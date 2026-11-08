/// Kontrak registrasi token perangkat ke backend.
abstract interface class DeviceRepository {
  Future<void> registerToken(String token);
}
