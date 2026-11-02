import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraksi penyimpanan key-value agar [TokenStore] bisa diuji tanpa
/// platform channel.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> deleteAll();
}

/// Implementasi produksi: Keychain (iOS) / Keystore (Android) lewat
/// flutter_secure_storage.
class SecureKeyValueStore implements KeyValueStore {
  const SecureKeyValueStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// Implementasi in-memory untuk unit test.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> deleteAll() async {
    _values.clear();
  }
}

/// Seluruh access/refresh token hanya keluar-masuk lewat kelas ini.
///
/// Refresh token TIDAK BOLEH disimpan di SharedPreferences karena datanya
/// tidak terenkripsi.
class TokenStore {
  TokenStore({KeyValueStore? storage})
      : _storage = storage ?? const SecureKeyValueStore();

  final KeyValueStore _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _fcmTokenKey = 'fcm_token';

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(_accessKey, access);
    await _storage.write(_refreshKey, refresh);
  }

  Future<String?> readAccess() => _storage.read(_accessKey);

  Future<String?> readRefresh() => _storage.read(_refreshKey);

  Future<void> saveFcmToken(String token) => _storage.write(_fcmTokenKey, token);

  Future<String?> readFcmToken() => _storage.read(_fcmTokenKey);

  Future<void> clear() => _storage.deleteAll();
}
