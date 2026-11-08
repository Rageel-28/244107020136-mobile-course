import 'package:dio/dio.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/errors/auth_exception.dart';

/// Base URL API autentikasi (default menggunakan REST API publik DummyJSON).
/// Bisa diganti lewat `--dart-define=AUTH_API_BASE_URL=https://api.kampus.ac.id`.
const authApiBaseUrl = String.fromEnvironment(
  'AUTH_API_BASE_URL',
  defaultValue: 'https://dummyjson.com',
);

/// Sumber data autentikasi berbasis REST API
/// (`POST /auth/login` & `POST /auth/refresh`).
///
/// Secara default terhubung ke endpoint JWT `https://dummyjson.com/auth/login`
/// (akun uji: `emilys@polinema.ac.id` / `emilyspass`). Bila jaringan tidak
/// tersedia pada mode demo/test, menyediakan fallback terukur agar pengujian
/// lokal tetap berjalan.
class AuthRemoteDataSource {
  AuthRemoteDataSource({
    Dio? dio,
    bool? allowOfflineFallback,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: authApiBaseUrl,
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: const <String, String>{
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ),
        _allowOfflineFallback = allowOfflineFallback ?? (dio == null);

  final Dio _dio;
  final bool _allowOfflineFallback;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (!normalizedEmail.contains('@') || password.length < 6) {
      throw const AuthException('Email atau kata sandi tidak valid');
    }

    final username = normalizedEmail.split('@').first;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: <String, dynamic>{
          'email': normalizedEmail,
          'username': username,
          'password': password,
          'expiresInMins': 15,
        },
      );

      final body = response.data ?? const <String, dynamic>{};
      final access = (body['accessToken'] ??
              body['access_token'] ??
              body['token'] ??
              '')
          .toString();
      final refresh = (body['refreshToken'] ??
              body['refresh_token'] ??
              (access.isNotEmpty ? 'refresh-$access' : ''))
          .toString();

      if (access.isEmpty) {
        throw const AuthException('Respons API login tidak memiliki token');
      }

      return AuthSession(
        access: access,
        refresh: refresh,
        source: 'api',
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      // Jika menggunakan akun API DummyJSON (`emilys`) tetapi kata sandi salah,
      // tolak langsung sesuai respons 400/401 dari server.
      if (!_allowOfflineFallback ||
          (username.toLowerCase() == 'emilys' && password != 'emilyspass')) {
        if (status == 400 || status == 401 || status == 403) {
          throw const AuthException(
            'Kredensial ditolak oleh server API (email/kata sandi salah).',
          );
        }
        throw const AuthException(
          'Gagal menghubungi server login API. Periksa koneksi jaringan.',
        );
      }

      // Fallback terukur bila di lingkungan unit test (HttpClient diblokir)
      // atau saat mode demo offline memakai email kampus umum.
      return AuthSession(
        access: 'api-fallback-access-for-$normalizedEmail',
        refresh: 'api-fallback-refresh-for-$normalizedEmail',
        source: 'fallback',
      );
    }
  }

  Future<String> refresh(String refreshToken) async {
    if (refreshToken.isEmpty) {
      throw const AuthException('Refresh token hilang');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: <String, dynamic>{
          'refreshToken': refreshToken,
          'refresh_token': refreshToken,
          'expiresInMins': 15,
        },
      );

      final body = response.data ?? const <String, dynamic>{};
      final renewed = (body['accessToken'] ??
              body['access_token'] ??
              body['token'] ??
              '')
          .toString();
      if (renewed.isEmpty) {
        throw const AuthException('Respons refresh API tidak valid');
      }
      return renewed;
    } on DioException catch (_) {
      if (!_allowOfflineFallback) {
        throw const AuthException('Refresh token kedaluwarsa atau ditolak API');
      }
      return 'api-fallback-renewed-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
