import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../repositories/token_repository.dart';

/// Login ke API lalu menyimpan access & refresh token secara aman.
class LoginUseCase {
  LoginUseCase({
    required this.authRepository,
    required this.tokenRepository,
  });

  final AuthRepository authRepository;
  final TokenRepository tokenRepository;

  Future<AuthSession> call(String email, String password) async {
    final session = await authRepository.login(
      email: email,
      password: password,
    );
    await tokenRepository.save(
      access: session.access,
      refresh: session.refresh,
    );
    return session;
  }
}
