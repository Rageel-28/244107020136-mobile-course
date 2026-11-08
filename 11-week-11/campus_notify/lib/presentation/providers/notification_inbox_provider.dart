import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/constants/app_routes.dart';
import '../../domain/entities/inbox_notification.dart';
import '../../domain/entities/push_message.dart';
import '../../domain/utils/route_parser.dart';

final notificationInboxProvider =
    NotifierProvider<NotificationInboxNotifier, List<InboxNotification>>(
  NotificationInboxNotifier.new,
);

/// Provider turunan untuk jumlah notifikasi belum dibaca pada badge ikon.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationInboxProvider).length;
});

class NotificationInboxNotifier extends Notifier<List<InboxNotification>> {
  int _counter = 3;

  static final List<InboxNotification> _initialItems = <InboxNotification>[
    InboxNotification(
      id: 'notif-1',
      announcementId: '1',
      title: 'Pendaftaran KRS Semester Ganjil',
      body: 'Batas akhir pengisian KRS 30 Oktober 2026 pukul 23.59 WIB.',
      route: AppRoutes.announcement('1'),
      receivedAt: DateTime(2026, 10, 26, 8, 30),
    ),
    InboxNotification(
      id: 'notif-2',
      announcementId: '2',
      title: 'Workshop Flutter & Firebase',
      body: 'Lab Mobile lantai 3, kuota 40 mahasiswa.',
      route: AppRoutes.announcement('2'),
      receivedAt: DateTime(2026, 10, 26, 10, 15),
    ),
    InboxNotification(
      id: 'notif-3',
      announcementId: '3',
      title: 'Jadwal kuliah berubah',
      body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00.',
      route: AppRoutes.announcement('3'),
      receivedAt: DateTime(2026, 10, 26, 12, 0),
    ),
  ];

  @override
  List<InboxNotification> build() {
    return List<InboxNotification>.unmodifiable(_initialItems);
  }

  /// Menambahkan notifikasi baru yang masuk (dari FCM atau simulasi) ke urutan
  /// paling atas daftar notifikasi dan menambah angka pada ikon notifikasi.
  InboxNotification addFromPushMessage(PushMessage message) {
    _counter++;
    final normalizedRoute = routeFromMessage(<String, dynamic>{
      'route': message.route,
    });
    final announcementId =
        announcementIdFromRoute(normalizedRoute) ??
        message.data['id']?.toString() ??
        '3';

    final item = InboxNotification(
      id: 'notif-$_counter-${DateTime.now().microsecondsSinceEpoch}',
      announcementId: announcementId,
      title: message.title,
      body: message.body,
      route: AppRoutes.announcement(announcementId),
      receivedAt: DateTime.now(),
    );

    state = <InboxNotification>[item, ...state];
    return item;
  }

  /// Menghapus notifikasi berdasarkan ID unik item ketika diklik/dibaca.
  void markAsReadById(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
  }

  /// Menghapus notifikasi yang cocok dengan rute `/pengumuman/:id` ketika
  /// dibuka dari banner sistem, snackbar, atau halaman detail.
  void markAsReadByRoute(String route) {
    final announcementId = announcementIdFromRoute(route);
    if (announcementId != null) {
      markAsReadByAnnouncementId(announcementId);
      return;
    }
    state = state.where((item) => item.route != route).toList(growable: false);
  }

  /// Menghapus satu atau seluruh notifikasi dengan `announcementId` terkait
  /// saat halaman pengumuman dibuka.
  void markAsReadByAnnouncementId(String announcementId) {
    final index = state.indexWhere(
      (item) => item.announcementId == announcementId,
    );
    if (index == -1) return;
    final updated = List<InboxNotification>.of(state)..removeAt(index);
    state = List<InboxNotification>.unmodifiable(updated);
  }
}
