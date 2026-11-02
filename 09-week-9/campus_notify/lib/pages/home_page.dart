import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../messaging/demo_push_service.dart';
import '../messaging/push_message.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_inbox_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _demoMessage = PushMessage(
    title: 'Jadwal kuliah berubah',
    body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
    route: '/pengumuman/3',
    data: <String, dynamic>{'id': '3', 'route': '/pengumuman/3'},
  );

  void _openNotification(
    BuildContext context,
    WidgetRef ref,
    InboxNotification item,
  ) {
    // Ketika dibaca/diklik, hapus dari daftar notifikasi masuk & kurangi badge icon.
    ref.read(notificationInboxProvider.notifier).markAsReadById(item.id);
    context.push(item.route);
  }

  void _showNotificationIconSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final inbox = sheetRef.watch(notificationInboxProvider);
            if (inbox.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 48),
                    SizedBox(height: 12),
                    Text('Semua notifikasi sudah dibaca.'),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_active_rounded),
                    title: Text('Notifikasi Masuk (${inbox.length})'),
                    subtitle: const Text('Ketuk untuk membaca (otomatis hilang)'),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: inbox.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = inbox[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.campaign_rounded),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(item.body),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _openNotification(context, sheetRef, item);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushService = ref.watch(pushServiceProvider);
    final demo = pushService is DemoPushService ? pushService : null;
    final inbox = ref.watch(notificationInboxProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Notifikasi Masuk ($unreadCount)',
            onPressed: () => _showNotificationIconSheet(context, ref),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: Icon(
                unreadCount > 0
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Debug',
            onPressed: () => context.push(AppRoutes.debug),
            icon: const Icon(Icons.bug_report_outlined),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (demo != null)
            const ListTile(
              leading: Icon(Icons.volume_up_rounded),
              title: Text('Simulasi FCM & Notifikasi Bersuara'),
              subtitle: Text(
                'Notifikasi baru masuk ke daftar & ikon lonceng dengan suara. '
                'Ketika diklik/dibaca, notifikasi otomatis hilang dari daftar.',
              ),
            ),
          if (demo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => demo.simulateForeground(_demoMessage),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Foreground (Bersuara)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => demo.simulateOpen(_demoMessage),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Buka deep link'),
                  ),
                ],
              ),
            ),
          const Divider(),
          ListTile(
            title: Text(
              'Daftar Notifikasi Masuk ($unreadCount belum dibaca)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Ketuk item untuk membaca pengumuman (otomatis hilang setelah dibaca)',
            ),
          ),
          if (inbox.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Center(
                child: Text(
                  'Tidak ada notifikasi baru. Semua notifikasi sudah dibaca.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            for (final item in inbox)
              ListTile(
                key: ValueKey<String>(item.id),
                leading: Badge(
                  smallSize: 10,
                  child: const CircleAvatar(
                    child: Icon(Icons.notifications_rounded),
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(item.body),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openNotification(context, ref, item),
              ),
        ],
      ),
    );
  }
}
