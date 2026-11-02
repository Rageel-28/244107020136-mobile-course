import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/device_repository.dart';
import '../data/token_store.dart';
import '../messaging/demo_push_service.dart';
import '../messaging/notification_presenter.dart';
import '../messaging/push_service.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final apiClientProvider = Provider<Dio>((ref) {
  return buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  );
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(
    dio: ref.watch(apiClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );

});

final notificationPresenterProvider = Provider<NotificationPresenter>((ref) {
  return NotificationPresenter();
});

/// Di-override di `main()` setelah Firebase dicoba diinisialisasi.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final pushServiceProvider = Provider<PushService>((ref) {
  final PushService service;
  if (ref.watch(firebaseReadyProvider)) {
    service = FirebasePushService(
      presenter: ref.watch(notificationPresenterProvider),
    );
  } else {
    service = DemoPushService(
      presenter: ref.watch(notificationPresenterProvider),
    );
  }
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
