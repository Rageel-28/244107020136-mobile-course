import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/messaging/push_message.dart';
import 'package:campus_notify/messaging/route_parser.dart';
import 'package:campus_notify/providers/notification_inbox_provider.dart';
import 'package:campus_notify/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({this.failRefresh = false});

  final bool failRefresh;
  int refreshCalls = 0;

  @override
  Future<String> refresh(String refreshToken) async {
    refreshCalls++;
    if (failRefresh) {
      throw const AuthException('Refresh token kedaluwarsa');
    }
    return 'renewed-access';
  }
}

void main() {
  group('routeFromMessage', () {
    test('mengembalikan home untuk payload kosong', () {
      expect(routeFromMessage(<String, dynamic>{}), AppRoutes.home);
    });

    test('menambahkan slash di depan rute', () {
      expect(
        routeFromMessage(<String, dynamic>{'route': 'pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('mempertahankan rute yang sudah memiliki slash', () {
      expect(
        routeFromMessage(<String, dynamic>{'route': '/pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('menolak rute yang tidak dikenal', () {
      expect(
        routeFromMessage(<String, dynamic>{'route': 'https://evil.example'}),
        AppRoutes.home,
      );
      expect(
        routeFromMessage(<String, dynamic>{'route': '/admin'}),
        AppRoutes.home,
      );
    });

    test('mengambil id pengumuman dari data payload', () {
      const data = <String, dynamic>{'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(announcementIdFromRoute('/pengumuman/3'), '3');
      expect(routeFromMessage(data), AppRoutes.announcement('3'));
    });
  });

  group('TokenStore', () {
    late TokenStore store;

    setUp(() {
      store = TokenStore(storage: InMemoryKeyValueStore());
    });

    test('menyimpan lalu membaca access dan refresh token', () async {
      await store.save(access: 'access-1', refresh: 'refresh-1');

      expect(await store.readAccess(), 'access-1');
      expect(await store.readRefresh(), 'refresh-1');
    });

    test('clear menghapus semua token termasuk token FCM', () async {
      await store.save(access: 'access-1', refresh: 'refresh-1');
      await store.saveFcmToken('fcm-1');

      await store.clear();

      expect(await store.readAccess(), isNull);
      expect(await store.readRefresh(), isNull);
      expect(await store.readFcmToken(), isNull);
    });
  });

  group('TokenRefresher', () {
    test('refresh berhasil menyimpan access token baru', () async {
      final store = TokenStore(storage: InMemoryKeyValueStore());
      await store.save(access: 'old-access', refresh: 'refresh-1');
      final refresher = TokenRefresher(
        store: store,
        auth: FakeAuthRepository(),
      );

      final renewed = await refresher.refreshAccessToken();

      expect(renewed, 'renewed-access');
      expect(await store.readAccess(), 'renewed-access');
      expect(await store.readRefresh(), 'refresh-1');
    });

    test('refresh gagal membersihkan sesi dan memaksa login ulang', () async {
      final store = TokenStore(storage: InMemoryKeyValueStore());
      await store.save(access: 'old-access', refresh: 'expired-refresh');
      final refresher = TokenRefresher(
        store: store,
        auth: FakeAuthRepository(failRefresh: true),
      );

      final renewed = await refresher.refreshAccessToken();

      expect(renewed, isNull);
      expect(await store.readAccess(), isNull);
      expect(await store.readRefresh(), isNull);
    });
  });

  group('AuthRepository', () {
    test('login valid menghasilkan sesi access dan refresh', () async {
      final session = await AuthRepository().login(
        email: 'mahasiswa@polinema.ac.id',
        password: 'rahasia123',
      );

      expect(session.access, contains('mahasiswa@polinema.ac.id'));
      expect(session.refresh, isNotEmpty);
    });

    test('email tidak valid ditolak', () async {
      expect(
        () => AuthRepository().login(
          email: 'bukan-email',
          password: 'rahasia123',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('NotificationInboxNotifier (list & icon badge)', () {
    test('notifikasi masuk menambah list & badge, dan hilang saat dibaca', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCount = container.read(unreadNotificationCountProvider);
      expect(initialCount, 3);

      // Notifikasi baru masuk -> masuk ke list paling atas & badge bertambah.
      final added = container
          .read(notificationInboxProvider.notifier)
          .addFromPushMessage(
            const PushMessage(
              title: 'Pengumuman Ujian Tengah Semester',
              body: 'Ruang Lab Mobile pukul 08.00 WIB',
              route: '/pengumuman/3',
            ),
          );

      expect(container.read(unreadNotificationCountProvider), initialCount + 1);
      expect(container.read(notificationInboxProvider).first.id, added.id);

      // Ketika dibaca/diklik -> hilang dari list & badge berkurang.
      container
          .read(notificationInboxProvider.notifier)
          .markAsReadById(added.id);

      expect(container.read(unreadNotificationCountProvider), initialCount);
      expect(
        container
            .read(notificationInboxProvider)
            .any((item) => item.id == added.id),
        isFalse,
      );
    });
  });
}
