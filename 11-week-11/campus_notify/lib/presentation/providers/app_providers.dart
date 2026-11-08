import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/device_remote_data_source.dart';
import '../../data/network/api_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../data/services/notification_presenter.dart';
import '../../data/services/push/demo_push_service.dart';
import '../../data/services/push/firebase_push_service.dart';
import '../../data/storage/token_store.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/repositories/push_service.dart';
import '../../domain/repositories/token_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_device_token_usecase.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final tokenRepositoryProvider = Provider<TokenRepository>((ref) {
  return ref.watch(tokenStoreProvider);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final apiClientProvider = Provider<Dio>((ref) {
  return buildApiClient(
    ref.watch(tokenRepositoryProvider),
    ref.watch(authRepositoryProvider),
  );
});

final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>((ref) {
  return DeviceRemoteDataSource(dio: ref.watch(apiClientProvider));
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(
    remoteDataSource: ref.watch(deviceRemoteDataSourceProvider),
    tokenRepository: ref.watch(tokenRepositoryProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(
    authRepository: ref.watch(authRepositoryProvider),
    tokenRepository: ref.watch(tokenRepositoryProvider),
  );
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(tokenRepository: ref.watch(tokenRepositoryProvider));
});

final registerDeviceTokenUseCaseProvider =
    Provider<RegisterDeviceTokenUseCase>((ref) {
  return RegisterDeviceTokenUseCase(
    deviceRepository: ref.watch(deviceRepositoryProvider),
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
