import 'package:dio/dio.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementasi [AuthRepository] yang meneruskan panggilan ke REST API.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    AuthRemoteDataSource? dataSource,
    Dio? dio,
    bool? allowOfflineFallback,
  }) : _dataSource = dataSource ??
            AuthRemoteDataSource(
              dio: dio,
              allowOfflineFallback: allowOfflineFallback,
            );

  final AuthRemoteDataSource _dataSource;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return _dataSource.login(email: email, password: password);
  }

  @override
  Future<String> refresh(String refreshToken) {
    return _dataSource.refresh(refreshToken);
  }
}
