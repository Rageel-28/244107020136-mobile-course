import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_errors.dart';
import 'token_store.dart';

/// Menyimpan registration token per perangkat dan mengirimkannya ke backend.
///
/// Endpoint yang diharapkan: `POST /devices`
/// body: `{ "fcm_token": "...", "platform": "android" }`
class DeviceRepository {
  DeviceRepository({required this.dio, required this.tokenStore});

  final Dio dio;
  final TokenStore tokenStore;

  Future<void> registerToken(String token) async {
    await tokenStore.saveFcmToken(token);

    final access = await tokenStore.readAccess();
    if (access == null || access.isEmpty) {
      // Belum login: token tetap disimpan lokal, dikirim setelah login.
      return;
    }

    try {
      await dio.post<dynamic>(
        '/devices',
        data: <String, String>{
          'fcm_token': token,
          'platform': defaultTargetPlatform.name,
        },
      );
    } on DioException catch (error) {
      // Jangan pernah log token. Cukup pesan ramah.
      debugPrint('Gagal mengirim token perangkat: ${friendlyApiError(error)}');
    }
  }
}
