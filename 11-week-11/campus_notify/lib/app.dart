import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/entities/inbox_notification.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/notification_inbox_provider.dart';
import 'presentation/router/app_router.dart';

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _pushStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPush();
    });
  }

  Future<void> _startPush() async {
    if (_pushStarted) return;
    _pushStarted = true;

    final pushService = ref.read(pushServiceProvider);
    final router = ref.read(routerProvider);

    try {
      await pushService.initialize(
        onToken: (token) async {
          await ref.read(registerDeviceTokenUseCaseProvider).call(token);
        },
        onOpenRoute: (route) {
          ref.read(notificationInboxProvider.notifier).markAsReadByRoute(route);
          router.go(route);
        },
        onForeground: (message) {
          final added = ref
              .read(notificationInboxProvider.notifier)
              .addFromPushMessage(message);
          _showForegroundBanner(added, router);
        },
      );
    } catch (error) {
      debugPrint('Push service gagal diinisialisasi: ${error.runtimeType}');
    }

    // Token yang tersimpan saat belum login perlu dikirim ulang setelah login.
    ref.listenManual<AsyncValue<bool>>(
      authStateProvider,
      (previous, next) async {
        if (next.value != true) return;
        final token = await ref.read(tokenRepositoryProvider).readFcmToken();
        if (token != null && token.isNotEmpty) {
          await ref.read(registerDeviceTokenUseCaseProvider).call(token);
        }
      },
      fireImmediately: true,
    );
  }

  void _showForegroundBanner(InboxNotification item, GoRouter router) {
    _messengerKey.currentState?.hideCurrentSnackBar();
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('🔔 ${item.title}: ${item.body}'),
        action: SnackBarAction(
          label: 'Baca',
          onPressed: () {
            ref
                .read(notificationInboxProvider.notifier)
                .markAsReadById(item.id);
            router.go(item.route);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      routerConfig: router,
    );
  }
}
