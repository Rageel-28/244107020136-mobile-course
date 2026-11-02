import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notification_inbox_provider.dart';
import '../routes.dart';

class AnnouncementPage extends ConsumerStatefulWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  static const _titles = <String, String>{
    '1': 'Pendaftaran KRS Semester Ganjil',
    '2': 'Workshop Flutter & Firebase',
    '3': 'Jadwal kuliah berubah',
  };

  static const _bodies = <String, String>{
    '1': 'Pengisian KRS dibuka sampai 30 Oktober 2026 pukul 23.59 WIB. '
        'Pastikan seluruh mata kuliah sudah disetujui dosen pembimbing.',
    '2': 'Workshop membahas autentikasi, secure storage, dan FCM. '
        'Pendaftaran dibuka untuk 40 mahasiswa di Lab Mobile lantai 3.',
    '3': 'Kelas Mobile pindah ke Ruang A2 jam 13.00. Perubahan berlaku '
        'mulai minggu ini.',
  };

  @override
  ConsumerState<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends ConsumerState<AnnouncementPage> {
  @override
  void initState() {
    super.initState();
    // Pastikan notifikasi dihapus dari daftar belum dibaca saat halaman
    // detail pengumuman dibuka (baik dari list, icon, maupun deep link banner).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(notificationInboxProvider.notifier)
          .markAsReadByAnnouncementId(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.id;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: const Text('Pengumuman'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Route: /pengumuman/$id'),
          const SizedBox(height: 16),
          Text(
            AnnouncementPage._titles[id] ?? 'Pengumuman #$id',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AnnouncementPage._bodies[id] ?? 'Detail pengumuman belum tersedia.',
          ),
          const SizedBox(height: 24),
          const Chip(
            avatar: Icon(Icons.check_circle_outline, size: 18),
            label: Text('Status: Sudah dibaca (dihapus dari daftar notifikasi masuk)'),
          ),
        ],
      ),
    );
  }
}
