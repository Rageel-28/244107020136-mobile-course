/// Hasil login: access token berumur pendek + refresh token berumur panjang.
class AuthSession {
  const AuthSession({
    required this.access,
    required this.refresh,
    this.source = 'api',
  });

  final String access;
  final String refresh;
  final String source;
}
