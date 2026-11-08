import '../repositories/device_repository.dart';

/// Menyimpan dan mengirim registration token perangkat ke backend.
class RegisterDeviceTokenUseCase {
  RegisterDeviceTokenUseCase({required this.deviceRepository});

  final DeviceRepository deviceRepository;

  Future<void> call(String token) => deviceRepository.registerToken(token);
}
