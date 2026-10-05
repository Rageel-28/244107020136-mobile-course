import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_mini_assignment/data/note_repository.dart';
import 'package:week5_mini_assignment/models/note.dart';
import 'package:week5_mini_assignment/providers/providers.dart';

/// In-memory fake used to test the provider layer without sqflite.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository([List<Note>? seed]) : _notes = [...?seed];

  final List<Note> _notes;
  int _nextId = 1;
  int syncCallCount = 0;

  @override
  Future<List<Note>> getNotes() async {
    return _notes
        .where((n) => !n.isDeleted)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<Note?> getNote(int id) async {
    for (final n in _notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  Future<Note> createNote(Note note) async {
    final saved = note.copyWith(id: _nextId++, isDirty: true);
    _notes.add(saved);
    return saved;
  }

  @override
  Future<Note> updateNote(Note note) async {
    final i = _notes.indexWhere((n) => n.id == note.id);
    final saved = note.copyWith(isDirty: true);
    if (i != -1) _notes[i] = saved;
    return saved;
  }

  @override
  Future<void> deleteNote(int id) async {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i != -1) {
      _notes[i] = _notes[i].copyWith(isDeleted: true, isDirty: true);
    }
  }

  @override
  Future<SyncResult> syncNotes() async {
    syncCallCount++;
    var synced = 0;
    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].isDirty) {
        _notes[i] = _notes[i].copyWith(isDirty: false);
        synced++;
      }
    }
    return SyncResult(synced: synced, failed: 0);
  }
}

ProviderContainer _containerWith(FakeNoteRepository repo) {
  final container = ProviderContainer(
    overrides: [noteRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final t1 = DateTime(2026, 5, 1, 10);
  final t2 = DateTime(2026, 5, 2, 10);

  test('loads notes newest-updated first and reports dirty count', () async {
    final repo = FakeNoteRepository([
      Note(id: 1, title: 'lama', content: 'a', updatedAt: t1),
      Note(id: 2, title: 'baru', content: 'b', updatedAt: t2, isDirty: false),
    ]);
    final container = _containerWith(repo);

    final state = await container.read(notesControllerProvider.future);

    expect(state.notes.map((n) => n.title), ['baru', 'lama']);
    expect(state.dirtyCount, 1);
  });

  test('addNote persists locally and marks it dirty (offline write)', () async {
    final repo = FakeNoteRepository();
    final container = _containerWith(repo);
    await container.read(notesControllerProvider.future);

    await container
        .read(notesControllerProvider.notifier)
        .addNote(title: 'Todo', content: 'Cuci mobil');

    final state = container.read(notesControllerProvider).requireValue;
    expect(state.notes, hasLength(1));
    expect(state.notes.single.title, 'Todo');
    expect(state.notes.single.isDirty, isTrue);
    expect(state.dirtyCount, 1);
  });

  test('sync clears dirty flags and calls the repository once', () async {
    final repo = FakeNoteRepository([
      Note(id: 1, title: 'a', content: 'b', updatedAt: t1),
    ]);
    final container = _containerWith(repo);
    await container.read(notesControllerProvider.future);

    final result =
        await container.read(notesControllerProvider.notifier).sync();

    expect(result.synced, 1);
    expect(repo.syncCallCount, 1);
    final state = container.read(notesControllerProvider).requireValue;
    expect(state.dirtyCount, 0);
    expect(state.lastSyncMessage, contains('1'));
  });

  test('deleteNote hides the note from the cache-first list', () async {
    final repo = FakeNoteRepository([
      Note(id: 1, title: 'a', content: 'b', updatedAt: t1),
    ]);
    final container = _containerWith(repo);
    await container.read(notesControllerProvider.future);

    await container.read(notesControllerProvider.notifier).removeNote(1);

    final state = container.read(notesControllerProvider).requireValue;
    expect(state.notes, isEmpty);
  });
}
