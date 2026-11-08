import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/push_message.dart';

/// Menampilkan banner lokal bersuara untuk notifikasi yang datang saat aplikasi
/// foreground maupun mode simulasi background/terminated.
///
/// Kelas ini juga menangani dua jalur klik:
/// * aplikasi sudah hidup -> `onDidReceiveNotificationResponse`
/// * aplikasi terminated -> `getNotificationAppLaunchDetails()`
class NotificationPresenter {
  NotificationPresenter({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _soundMethodChannel =
      MethodChannel('id.polinema.campus_notify/sound');

  static const _channelId = 'pengumuman_bersuara';
  static const _channelName = 'Pengumuman Kampus (Bersuara)';
  static const _channelDescription =
      'Notifikasi pengumuman kampus dengan suara dan getar';

  static const _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  Future<void> initialize(void Function(String route) onTap) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          onTap(payload);
        }
      },
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();

    // Aplikasi dibuka dari notifikasi saat proses belum berjalan.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        onTap(payload);
      }
    }
  }

  /// Memutar suara notifikasi sistem agar terdengar jelas baik di foreground
  /// maupun background.
  Future<void> playNotificationSound() async {
    try {
      await _soundMethodChannel.invokeMethod<bool>('playNotificationSound');
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {
        // Abaikan pada lingkungan unit test tanpa binding platform.
      }
    }
  }

  /// [delay] dipakai mode demo agar penguji sempat menekan Home sebelum
  /// banner muncul, sehingga perilaku background bisa diamati.
  /// [badgeCount] mengatur angka badge pada icon notifikasi sistem/launcher.
  Future<void> show(
    PushMessage message, {
    Duration delay = Duration.zero,
    int? badgeCount,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    await playNotificationSound();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        number: badgeCount,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: badgeCount,
      ),
    );

    await _plugin.show(
      id: message.hashCode,
      title: message.title,
      body: message.body,
      notificationDetails: details,
      payload: message.route,
    );
  }
}

/// Dipakai saat platform tidak mendukung local notification
/// (mis. unit test atau web).
void logNotificationFallback(Object error) {
  debugPrint('Local notification tidak tersedia: ${error.runtimeType}');
}
