import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/note_repository.dart';
import '../data/preferences_service.dart';
import '../models/note.dart';

/// Overridden in `main()` with the real sqflite-backed repository and in tests
/// with a fake. Throws by default to make the missing override obvious.
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  throw UnimplementedError(
    'noteRepositoryProvider must be overridden in ProviderScope',
  );
});

/// Overridden in `main()` after `PreferencesService.create()` resolves.
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError(
    'preferencesServiceProvider must be overridden in ProviderScope',
  );
});

/// Dark mode toggle, persisted through SharedPreferences.
class ThemeModeNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesServiceProvider).isDarkMode;

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await ref.read(preferencesServiceProvider).setDarkMode(next);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, bool>(ThemeModeNotifier.new);

/// Last-app-opened timestamp, persisted through SharedPreferences.
final lastOpenedProvider = Provider<DateTime?>((ref) {
  return ref.watch(preferencesServiceProvider).lastOpened;
});

/// State exposed to the notes screen, including sync feedback.
class NotesState {
  const NotesState({
    required this.notes,
    this.isSyncing = false,
    this.lastSyncMessage,
  });

  final List<Note> notes;
  final bool isSyncing;
  final String? lastSyncMessage;

  int get dirtyCount => notes.where((n) => n.isDirty).length;

  NotesState copyWith({
    List<Note>? notes,
    bool? isSyncing,
    String? lastSyncMessage,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncMessage: lastSyncMessage ?? this.lastSyncMessage,
    );
  }
}

/// Cache-first controller. Reads always come from the local repository; writes
/// mutate local storage first (optimistic/offline) and only then sync.
class NotesController extends AsyncNotifier<NotesState> {
  NoteRepository get _repo => ref.read(noteRepositoryProvider);

  @override
  Future<NotesState> build() async {
    // Cache-first: render whatever is stored locally, no network needed.
    final notes = await _repo.getNotes();
    return NotesState(notes: notes);
  }

  Future<void> _refresh() async {
    final notes = await _repo.getNotes();
    state = AsyncData(NotesState(notes: notes));
  }

  Future<void> addNote({required String title, required String content}) async {
    final now = DateTime.now();
    await _repo.createNote(
      Note(title: title, content: content, updatedAt: now, createdAt: now),
    );
    await _refresh();
  }

  Future<void> editNote(Note note) async {
    await _repo.updateNote(note);
    await _refresh();
  }

  Future<void> removeNote(int id) async {
    await _repo.deleteNote(id);
    await _refresh();
  }

  /// Pushes dirty rows to the remote and refreshes the cache-first list.
  Future<SyncResult> sync() async {
    state = AsyncData((state.valueOrNull ?? const NotesState(notes: []))
        .copyWith(isSyncing: true));
    final result = await _repo.syncNotes();
    final notes = await _repo.getNotes();
    state = AsyncData(
      NotesState(
        notes: notes,
        isSyncing: false,
        lastSyncMessage: result.failed == 0
            ? 'Tersinkron: ${result.synced} catatan'
            : 'Tersinkron: ${result.synced}, gagal: ${result.failed}',
      ),
    );
    return result;
  }
}

final notesControllerProvider =
    AsyncNotifierProvider<NotesController, NotesState>(NotesController.new);
