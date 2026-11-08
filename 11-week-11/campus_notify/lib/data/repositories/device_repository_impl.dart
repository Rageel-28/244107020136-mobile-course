import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/device_repository.dart';
import '../../domain/repositories/token_repository.dart';
import '../datasources/device_remote_data_source.dart';
import '../network/api_errors.dart';

/// Menyimpan registration token perangkat lalu mengirimkannya ke backend.
class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenRepository,
  });

  final DeviceRemoteDataSource remoteDataSource;
  final TokenRepository tokenRepository;

  @override
  Future<void> registerToken(String token) async {
    await tokenRepository.saveFcmToken(token);

    final access = await tokenRepository.readAccess();
    if (access == null || access.isEmpty) {
      // Belum login: token tetap disimpan lokal, dikirim setelah login.
      return;
    }

    try {
      await remoteDataSource.registerToken(token);
    } on DioException catch (error) {
      // Jangan pernah log token. Cukup pesan ramah.
      debugPrint('Gagal mengirim token perangkat: ${friendlyApiError(error)}');
    }
  }
}
