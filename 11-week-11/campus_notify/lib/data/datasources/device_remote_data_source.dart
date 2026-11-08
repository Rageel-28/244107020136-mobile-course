import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Mengirim registration token perangkat ke backend.
///
/// Endpoint yang diharapkan: `POST /devices`
/// body: `{ "fcm_token": "...", "platform": "android" }`
class DeviceRemoteDataSource {
  DeviceRemoteDataSource({required this.dio});

  final Dio dio;

  Future<void> registerToken(String token) async {
    await dio.post<dynamic>(
      '/devices',
      data: <String, String>{
        'fcm_token': token,
        'platform': defaultTargetPlatform.name,
      },
    );
  }
}
