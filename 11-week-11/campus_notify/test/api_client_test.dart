import 'dart:convert';
import 'dart:io';

import 'package:campus_notify/data/datasources/device_remote_data_source.dart';
import 'package:campus_notify/data/network/api_client.dart';
import 'package:campus_notify/data/network/api_errors.dart';
import 'package:campus_notify/data/repositories/auth_repository_impl.dart';
import 'package:campus_notify/data/repositories/device_repository_impl.dart';
import 'package:campus_notify/data/storage/key_value_store.dart';
import 'package:campus_notify/data/storage/token_store.dart';
import 'package:campus_notify/domain/errors/auth_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository extends AuthRepositoryImpl {
  FakeAuthRepository({this.failRefresh = false});

  final bool failRefresh;
  int refreshCalls = 0;

  @override
  Future<String> refresh(String refreshToken) async {
    refreshCalls++;
    if (failRefresh) {
      throw const AuthException('Refresh token kedaluwarsa');
    }
    return 'renewed-access';
  }
}

void main() {
  group('AuthRepository API login & refresh', () {
    test('login memanggil POST /auth/login dan mengembalikan JWT dari API', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      Map<String, dynamic>? receivedLoginBody;

      server.listen((request) async {
        final content = await utf8.decoder.bind(request).join();
        receivedLoginBody = jsonDecode(content) as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, String>{
            'accessToken': 'jwt-access-from-api',
            'refreshToken': 'jwt-refresh-from-api',
          }),
        );
        await request.response.close();
      });

      final repo = AuthRepositoryImpl(
        dio: Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}')),
      );

      final session = await repo.login(
        email: 'emilys@polinema.ac.id',
        password: 'emilyspass',
      );

      expect(receivedLoginBody?['username'], 'emilys');
      expect(receivedLoginBody?['email'], 'emilys@polinema.ac.id');
      expect(session.access, 'jwt-access-from-api');
      expect(session.refresh, 'jwt-refresh-from-api');
      expect(session.source, 'api');
    });
  });

  group('Dio refresh otomatis', () {
    test('401 memicu refresh sekali lalu mengulang request', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      var calls = 0;
      final authorizationHeaders = <String?>[];

      server.listen((request) async {
        calls++;
        authorizationHeaders.add(request.headers.value('authorization'));
        request.response.headers.contentType = ContentType.json;

        if (calls == 1) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('{"error":"expired"}');
        } else {
          request.response.write('{"ok":true}');
        }
        await request.response.close();
      });

      final store = TokenStore(storage: InMemoryKeyValueStore());
      await store.save(access: 'expired-access', refresh: 'valid-refresh');
      final auth = FakeAuthRepository();
      final dio = buildApiClient(
        store,
        auth,
        baseUrl: 'http://127.0.0.1:${server.port}',
      );

      final response = await dio.get<dynamic>('/devices');

      expect(response.statusCode, 200);
      expect(calls, 2);
      expect(auth.refreshCalls, 1);
      expect(authorizationHeaders.first, 'Bearer expired-access');
      expect(authorizationHeaders.last, 'Bearer renewed-access');
      expect(await store.readAccess(), 'renewed-access');
      expect(await store.readRefresh(), 'valid-refresh');
    });

    test('refresh gagal meneruskan 401 dan membersihkan sesi', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      var calls = 0;
      server.listen((request) async {
        calls++;
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write('{"error":"expired"}');
        await request.response.close();
      });

      final store = TokenStore(storage: InMemoryKeyValueStore());
      await store.save(access: 'expired-access', refresh: 'expired-refresh');
      final auth = FakeAuthRepository(failRefresh: true);
      final dio = buildApiClient(
        store,
        auth,
        baseUrl: 'http://127.0.0.1:${server.port}',
      );

      await expectLater(
        dio.get<dynamic>('/devices'),
        throwsA(isA<DioException>()),
      );

      expect(calls, 1);
      expect(auth.refreshCalls, 1);
      expect(await store.readAccess(), isNull);
      expect(await store.readRefresh(), isNull);
    });

    test('DeviceRepository mengirim fcm_token baru ke POST /devices', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      Map<String, dynamic>? receivedBody;
      String? receivedPath;

      server.listen((request) async {
        receivedPath = request.uri.path;
        final content = await utf8.decoder.bind(request).join();
        receivedBody = jsonDecode(content) as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"registered":true}');
        await request.response.close();
      });

      final store = TokenStore(storage: InMemoryKeyValueStore());
      await store.save(access: 'valid-access', refresh: 'valid-refresh');
      final dio = buildApiClient(
        store,
        FakeAuthRepository(),
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      final devices = DeviceRepositoryImpl(
        remoteDataSource: DeviceRemoteDataSource(dio: dio),
        tokenRepository: store,
      );

      await devices.registerToken('fcm-token-rotated-123');

      expect(await store.readFcmToken(), 'fcm-token-rotated-123');
      expect(receivedPath, '/devices');
      expect(receivedBody?['fcm_token'], 'fcm-token-rotated-123');
      expect(receivedBody?['platform'], isNotEmpty);
    });
  });

  group('friendlyApiError', () {
    test('memetakan 401 menjadi ajakan login ulang', () {
      final options = RequestOptions(path: '/devices');
      final error = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 401,
        ),
      );

      expect(friendlyApiError(error), contains('login ulang'));
    });

    test('memetakan timeout dan offline', () {
      final options = RequestOptions(path: '/devices');

      expect(
        friendlyApiError(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        contains('Koneksi terlalu lama'),
      );
      expect(
        friendlyApiError(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
        contains('Tidak ada koneksi internet'),
      );
    });
  });
}
