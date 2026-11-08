import '../repositories/auth_repository.dart';
import '../repositories/token_repository.dart';

/// Menukar refresh token menjadi access token baru.
///
/// Dipisah dari interceptor agar logika "refresh mati -> bersihkan sesi"
/// dapat diuji tanpa Firebase maupun jaringan.
class RefreshAccessTokenUseCase {
  RefreshAccessTokenUseCase({
    required this.tokenRepository,
    required this.authRepository,
  });

  final TokenRepository tokenRepository;
  final AuthRepository authRepository;

  /// Mengembalikan access token baru, atau `null` bila sesi harus diakhiri.
  Future<String?> call() async {
    final refreshToken = await tokenRepository.readRefresh();
    if (refreshToken == null || refreshToken.isEmpty) {
      await tokenRepository.clear();
      return null;
    }

    try {
      final renewed = await authRepository.refresh(refreshToken);
      await tokenRepository.save(access: renewed, refresh: refreshToken);
      return renewed;
    } catch (_) {
      await tokenRepository.clear();
      return null;
    }
  }
}
