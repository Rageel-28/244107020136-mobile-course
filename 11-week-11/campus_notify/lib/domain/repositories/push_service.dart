import '../entities/push_message.dart';

typedef TokenCallback = Future<void> Function(String token);
typedef RouteCallback = void Function(String route);
typedef ForegroundCallback = void Function(PushMessage message);

/// Kontrak layanan push (FCM atau mode demo).
abstract interface class PushService {
  bool get isFirebase;

  Future<void> initialize({
    required TokenCallback onToken,
    required RouteCallback onOpenRoute,
    required ForegroundCallback onForeground,
  });

  Future<String?> currentToken();

  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);

  Future<void> dispose();
}
