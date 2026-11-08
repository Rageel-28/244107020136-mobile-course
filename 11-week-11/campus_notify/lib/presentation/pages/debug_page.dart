import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/push/demo_push_service.dart';
import '../../domain/constants/push_topics.dart';
import '../../domain/entities/push_message.dart';
import '../providers/app_providers.dart';
import '../providers/notification_inbox_provider.dart';

class DebugPage extends ConsumerStatefulWidget {
  const DebugPage({super.key});

  @override
  ConsumerState<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends ConsumerState<DebugPage> {
  String? _token;

  static const _demoMessage = PushMessage(
    title: 'Jadwal kuliah berubah',
    body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
    route: '/pengumuman/3',
    data: <String, dynamic>{'id': '3', 'route': '/pengumuman/3'},
  );

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await ref.read(pushServiceProvider).currentToken();
    if (!mounted) return;
    setState(() => _token = token);
  }

  String get _truncatedToken {
    final token = _token;
    if (token == null || token.isEmpty) return 'Belum tersedia';
    return '${token.substring(0, token.length < 12 ? token.length : 12)}...';
  }

  @override
  Widget build(BuildContext context) {
    final pushService = ref.watch(pushServiceProvider);
    final presenter = ref.watch(notificationPresenterProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final demo = pushService is DemoPushService ? pushService : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug FCM'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('Registration token (dipotong)'),
            subtitle: Text(_truncatedToken),
            trailing: IconButton(
              tooltip: 'Muat ulang token',
              onPressed: _loadToken,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.topic_outlined),
            title: Text('Topik $announcementTopic'),
            subtitle: Text(pushService.isFirebase ? 'FCM aktif' : 'Mode demo'),
          ),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => pushService.subscribeToTopic(announcementTopic),
                child: const Text('Subscribe'),
              ),
              ElevatedButton(
                onPressed: () =>
                    pushService.unsubscribeFromTopic(announcementTopic),
                child: const Text('Unsubscribe'),
              ),
            ],
          ),
          if (demo != null) ...[
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.notifications_active_outlined),
              title: Text('Simulasi notifikasi (bersuara + masuk list & icon)'),
              subtitle: Text('Foreground, background, suara, dan klik deep link.'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => demo.simulateForeground(_demoMessage),
                  child: const Text('Foreground'),
                ),
                ElevatedButton(
                  onPressed: () => demo.simulateBackground(_demoMessage),
                  child: const Text('Background (5 detik)'),
                ),
                ElevatedButton(
                  onPressed: () => demo.simulateOpen(_demoMessage),
                  child: const Text('Buka deep link'),
                ),
                OutlinedButton.icon(
                  onPressed: presenter.playNotificationSound,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Uji Suara'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
