import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'messaging/push_service.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await _initializeFirebase();
  final container = ProviderContainer(
    overrides: [
      firebaseReadyProvider.overrideWithValue(firebaseReady),
    ],
  );

  // Selesaikan pembacaan token sebelum router dibuat agar guard tidak
  // sempat melempar pengguna yang sudah login ke /login.
  await container.read(authStateProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CampusNotifyApp(),
    ),
  );
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
    }
    return true;
  } catch (error) {
    // Tanpa google-services.json / GoogleService-Info.plist, aplikasi tetap
    // bisa dijalankan dalam mode demo.
    debugPrint(
      'Firebase belum dikonfigurasi; memakai mode demo '
      '(${error.runtimeType}).',
    );
    return false;
  }
}
