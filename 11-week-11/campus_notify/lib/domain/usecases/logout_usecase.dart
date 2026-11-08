import '../repositories/token_repository.dart';

/// Menghapus seluruh token sesi saat pengguna keluar.
class LogoutUseCase {
  LogoutUseCase({required this.tokenRepository});

  final TokenRepository tokenRepository;

  Future<void> call() => tokenRepository.clear();
}
