import 'package:flutter/foundation.dart';

import '../../../domain/constants/push_topics.dart';
import '../../../domain/entities/push_message.dart';
import '../../../domain/repositories/push_service.dart';
import '../notification_presenter.dart';

/// Mode demo dipakai ketika Firebase belum dikonfigurasi
/// (`google-services.json` belum tersedia).
///
/// Mode ini tidak menggantikan FCM. Tujuannya agar alur permission, token,
/// topik, suara notifikasi, daftar notifikasi masuk, badge icon, dan deep link
/// tetap bisa dicoba tanpa project Firebase.
class DemoPushService implements PushService {
  DemoPushService({NotificationPresenter? presenter})
      : _presenter = presenter ?? NotificationPresenter();

  final NotificationPresenter _presenter;

  RouteCallback? _onOpenRoute;
  ForegroundCallback? _onForeground;

  String? _token;
  bool _topicSubscribed = false;

  @override
  bool get isFirebase => false;

  bool get topicSubscribed => _topicSubscribed;

  @override
  Future<void> initialize({
    required TokenCallback onToken,
    required RouteCallback onOpenRoute,
    required ForegroundCallback onForeground,
  }) async {
    _onOpenRoute = onOpenRoute;
    _onForeground = onForeground;

    try {
      await _presenter.initialize((route) => _onOpenRoute?.call(route));
    } catch (error) {
      logNotificationFallback(error);
    }

    _token = 'demo-fcm-token-${DateTime.now().millisecondsSinceEpoch}';
    await onToken(_token!);
    await subscribeToTopic(announcementTopic);
  }

  /// Meniru `FirebaseMessaging.onMessage` saat aplikasi foreground:
  /// memasukkan notifikasi ke list + badge icon dan memutar suara notifikasi.
  Future<void> simulateForeground(PushMessage message) async {
    _onForeground?.call(message);
    try {
      await _presenter.show(message);
    } catch (error) {
      logNotificationFallback(error);
    }
  }

  /// Meniru pesan yang tiba saat aplikasi background/terminated.
  ///
  /// Banner ditunda [delay] agar penguji bisa menekan Home atau mematikan
  /// proses lebih dulu, lalu membuktikan klik notifikasi tetap masuk ke rute
  /// yang benar dan bersuara.
  Future<void> simulateBackground(
    PushMessage message, {
    Duration delay = const Duration(seconds: 5),
  }) async {
    try {
      await _presenter.show(message, delay: delay);
      _onForeground?.call(message);
    } catch (error) {
      logNotificationFallback(error);
    }
  }

  /// Meniru klik notifikasi pada state background/terminated.
  Future<void> simulateOpen(PushMessage message) async {
    _onOpenRoute?.call(message.route);
  }

  @override
  Future<String?> currentToken() async => _token;

  @override
  Future<void> subscribeToTopic(String topic) async {
    _topicSubscribed = true;
    debugPrint('Demo: berlangganan topik $topic');
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    _topicSubscribed = false;
    debugPrint('Demo: berhenti berlangganan topik $topic');
  }

  @override
  Future<void> dispose() async {}
}
