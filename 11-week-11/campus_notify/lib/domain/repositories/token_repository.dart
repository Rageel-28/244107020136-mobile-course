/// Kontrak penyimpanan token yang aman.
abstract interface class TokenRepository {
  Future<void> save({required String access, required String refresh});

  Future<String?> readAccess();

  Future<String?> readRefresh();

  Future<void> saveFcmToken(String token);

  Future<String?> readFcmToken();

  Future<void> clear();
}
