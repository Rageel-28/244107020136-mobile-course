import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_inbox_provider.dart';

/// Bottom sheet daftar notifikasi masuk.
///
/// Item yang diketuk akan dihapus dari daftar belum dibaca lalu rutenya
/// diteruskan ke [onOpen] agar halaman induk yang melakukan navigasi.
class NotificationInboxSheet extends ConsumerWidget {
  const NotificationInboxSheet({super.key, required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationInboxProvider);
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
                    ref
                        .read(notificationInboxProvider.notifier)
                        .markAsReadById(item.id);
                    Navigator.of(context).pop();
                    onOpen(item.route);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
