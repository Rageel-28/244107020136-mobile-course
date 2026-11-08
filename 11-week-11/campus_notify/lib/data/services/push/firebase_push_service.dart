import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/constants/push_topics.dart';
import '../../../domain/repositories/push_service.dart';
import '../../../domain/utils/route_parser.dart';
import '../../mappers/push_message_mapper.dart';
import '../notification_presenter.dart';

/// Handler background WAJIB top-level dan berjalan di isolate terpisah.
///
/// Jangan akses BuildContext, Riverpod, atau navigasi di sini. Navigasi
/// dilakukan saat notifikasi diklik lewat `onMessageOpenedApp` /
/// `getInitialMessage`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Sengaja tidak melakukan apa pun selain menerima pesan. Bila perlu,
  // simpan ringkasan ke storage lokal di sini.
  debugPrint('Pesan background diterima: ${message.messageId}');
}

/// Implementasi FCM sungguhan.
class FirebasePushService implements PushService {
  FirebasePushService({
    FirebaseMessaging? messaging,
    NotificationPresenter? presenter,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _presenter = presenter ?? NotificationPresenter();

  final FirebaseMessaging _messaging;
  final NotificationPresenter _presenter;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  bool get isFirebase => true;

  @override
  Future<void> initialize({
    required TokenCallback onToken,
    required RouteCallback onOpenRoute,
    required ForegroundCallback onForeground,
  }) async {
    try {
      await _presenter.initialize(onOpenRoute);
    } catch (error) {
      logNotificationFallback(error);
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return;

    // ignore: deprecated_member_use
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await onToken(token);
    }

    // Listener ini wajib ada: token bisa berubah setelah reinstall,
    // clear data, atau rotasi keamanan. Tanpa ini backend menyimpan token basi.
    // ignore: deprecated_member_use
    _subscriptions.add(_messaging.onTokenRefresh.listen(onToken));

    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((message) async {
        final push = pushMessageFromRemote(message);
        onForeground(push);
        try {
          await _presenter.show(push);
        } catch (error) {
          logNotificationFallback(error);
        }
      }),
    );

    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        onOpenRoute(routeFromMessage(message.data));
      }),
    );

    // Terminated: aplikasi dibuka dari notifikasi.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      onOpenRoute(routeFromMessage(initial.data));
    }

    await subscribeToTopic(announcementTopic);
  }

  @override
  Future<String?> currentToken() async {
    // ignore: deprecated_member_use
    return _messaging.getToken();
  }

  @override
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}
