import '../../domain/repositories/token_repository.dart';
import 'key_value_store.dart';

/// Seluruh access/refresh token hanya keluar-masuk lewat kelas ini.
///
/// Refresh token TIDAK BOLEH disimpan di SharedPreferences karena datanya
/// tidak terenkripsi.
class TokenStore implements TokenRepository {
  TokenStore({KeyValueStore? storage})
      : _storage = storage ?? const SecureKeyValueStore();

  final KeyValueStore _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _fcmTokenKey = 'fcm_token';

  @override
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(_accessKey, access);
    await _storage.write(_refreshKey, refresh);
  }

  @override
  Future<String?> readAccess() => _storage.read(_accessKey);

  @override
  Future<String?> readRefresh() => _storage.read(_refreshKey);

  @override
  Future<void> saveFcmToken(String token) => _storage.write(_fcmTokenKey, token);

  @override
  Future<String?> readFcmToken() => _storage.read(_fcmTokenKey);

  @override
  Future<void> clear() => _storage.deleteAll();
}
