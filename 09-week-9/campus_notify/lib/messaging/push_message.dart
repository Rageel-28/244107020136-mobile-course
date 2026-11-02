import 'package:firebase_messaging/firebase_messaging.dart';

import 'route_parser.dart';

/// Representasi payload gabungan `notification + data`.
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    required this.route,
    this.data = const <String, dynamic>{},
  });

  factory PushMessage.fromRemote(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    return PushMessage(
      title: message.notification?.title ??
          data['title']?.toString() ??
          'Pengumuman Kampus',
      body: message.notification?.body ?? data['body']?.toString() ?? '',
      route: routeFromMessage(data),
      data: data,
    );
  }

  final String title;
  final String body;
  final String route;
  final Map<String, dynamic> data;
}
