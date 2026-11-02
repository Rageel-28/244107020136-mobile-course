import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

/// Base URL bisa diganti tanpa mengubah kode:
/// `flutter run --dart-define=CAMPUS_API_BASE_URL=https://api.kampus.ac.id`
const campusApiBaseUrl = String.fromEnvironment(
  'CAMPUS_API_BASE_URL',
  defaultValue: 'https://example-campus-api.test',
);

/// Menukar refresh token menjadi access token baru.
///
/// Dipisah dari interceptor agar logika "refresh mati -> bersihkan sesi"
/// dapat diuji tanpa Firebase maupun jaringan.
class TokenRefresher {
  TokenRefresher({required this.store, required this.auth});

  final TokenStore store;
  final AuthRepository auth;

  /// Mengembalikan access token baru, atau `null` bila sesi harus diakhiri.
  Future<String?> refreshAccessToken() async {
    final refreshToken = await store.readRefresh();
    if (refreshToken == null || refreshToken.isEmpty) {
      await store.clear();
      return null;
    }

    try {
      final renewed = await auth.refresh(refreshToken);
      await store.save(access: renewed, refresh: refreshToken);
      return renewed;
    } catch (_) {
      await store.clear();
      return null;
    }
  }
}

/// Dio dengan:
/// 1. header `Authorization: Bearer <access>` otomatis,
/// 2. refresh sekali saat 401 lalu mengulang request satu kali,
/// 3. logout paksa (clear token) bila refresh ikut kedaluwarsa.
Dio buildApiClient(
  TokenStore store,
  AuthRepository auth, {
  String? baseUrl,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? campusApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final refresher = TokenRefresher(store: store, auth: auth);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (isUnauthorized && !alreadyRetried) {
          final renewed = await refresher.refreshAccessToken();
          if (renewed != null) {
            try {
              final options = error.requestOptions;
              options.extra['retried'] = true;
              options.headers['Authorization'] = 'Bearer $renewed';
              final response = await dio.fetch<dynamic>(options);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }
        }

        handler.next(error);
      },
    ),
  );

  return dio;
}
