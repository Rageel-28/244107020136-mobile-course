import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
 
import '../data/local/note.dart';
import '../providers/note_providers.dart';
import '../widgets/note_form_dialog.dart';
 
class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.id});
 
  final int id;
 
  Future<void> _edit(WidgetRef ref, BuildContext context, Note note) async {
    final result = await showDialog<NoteFormResult>(
      context: context,
      builder: (_) => NoteFormDialog(initial: note),
    );
    if (result == null) return;
    await ref.read(noteActionsProvider).update(
          note.copyWith(title: result.title, body: result.body),
        );
  }
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dibaca langsung dari repository lokal, bukan dari state halaman list.
    final noteAsync = ref.watch(noteByIdProvider(id));
    final note = noteAsync.value;
 
    return Scaffold(
      appBar: AppBar(title: const Text('Detail catatan')),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal membaca catatan: $e')),
        data: (current) {
          if (current == null) {
            return const Center(child: Text('Catatan tidak ditemukan'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                current.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      current.dirty ? Icons.cloud_off : Icons.cloud_done,
                      size: 18,
                      color: current.dirty ? Colors.orange : Colors.green,
                    ),
                    label: Text(
                      current.dirty ? 'Belum tersinkron' : 'Sudah tersinkron',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Diubah ${current.updatedAt.toLocal().toString().split('.').first}',
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                current.body.isEmpty ? '(tanpa isi)' : current.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          );
        },
      ),
      floatingActionButton: note == null
          ? null
          : FloatingActionButton(
              tooltip: 'Ubah catatan',
              onPressed: () => _edit(ref, context, note),
              child: const Icon(Icons.edit_outlined),
            ),
    );
  }
}
