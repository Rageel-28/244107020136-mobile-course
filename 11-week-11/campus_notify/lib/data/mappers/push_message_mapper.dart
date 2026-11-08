import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/entities/push_message.dart';
import '../../domain/utils/route_parser.dart';

/// Mengubah [RemoteMessage] dari Firebase menjadi entity domain.
PushMessage pushMessageFromRemote(RemoteMessage message) {
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
