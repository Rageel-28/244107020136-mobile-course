import 'package:dio/dio.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/token_repository.dart';
import '../../domain/usecases/refresh_access_token_usecase.dart';

/// Base URL bisa diganti tanpa mengubah kode:
/// `flutter run --dart-define=CAMPUS_API_BASE_URL=https://api.kampus.ac.id`
const campusApiBaseUrl = String.fromEnvironment(
  'CAMPUS_API_BASE_URL',
  defaultValue: 'https://example-campus-api.test',
);

/// Dio dengan:
/// 1. header `Authorization: Bearer <access>` otomatis,
/// 2. refresh sekali saat 401 lalu mengulang request satu kali,
/// 3. logout paksa (clear token) bila refresh ikut kedaluwarsa.
Dio buildApiClient(
  TokenRepository tokenRepository,
  AuthRepository authRepository, {
  String? baseUrl,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? campusApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final refresher = RefreshAccessTokenUseCase(
    tokenRepository: tokenRepository,
    authRepository: authRepository,
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await tokenRepository.readAccess();
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (isUnauthorized && !alreadyRetried) {
          final renewed = await refresher.call();
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
