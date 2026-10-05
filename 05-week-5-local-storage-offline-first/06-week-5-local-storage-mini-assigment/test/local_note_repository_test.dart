import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:week5_mini_assignment/data/app_database.dart';
import 'package:week5_mini_assignment/data/local_note_repository.dart';
import 'package:week5_mini_assignment/models/note.dart';

/// Integration test for the real sqflite repository, running on the Dart VM
/// via `sqflite_common_ffi` with an in-memory database.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase db;
  late LocalNoteRepository repo;

  setUp(() async {
    db = AppDatabase(databaseName: inMemoryDatabasePath);
    repo = LocalNoteRepository(database: db);
    await db.database; // force schema creation
  });

  tearDown(() async => db.close());

  test('persists a note and reads it back cleanly after sync', () async {
    final created = await repo.createNote(
      Note(title: 'Belanja', content: 'Beli kopi', updatedAt: DateTime.now()),
    );
    expect(created.id, isNotNull);

    var notes = await repo.getNotes();
    expect(notes.single.title, 'Belanja');
    expect(notes.single.isDirty, isTrue);

    final result = await repo.syncNotes();
    expect(result.synced, 1);
    expect(result.failed, 0);

    notes = await repo.getNotes();
    expect(notes.single.isDirty, isFalse);
  });

  test('orders notes by updated_at descending', () async {
    await repo.createNote(
      Note(title: 'lama', content: '', updatedAt: DateTime(2020)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.createNote(
      Note(title: 'baru', content: '', updatedAt: DateTime(2021)),
    );

    final notes = await repo.getNotes();
    expect(notes.first.title, 'baru');
    expect(notes.last.title, 'lama');
  });

  test('soft delete hides the note and purge happens after sync', () async {
    final created = await repo.createNote(
      Note(title: 'hapus aku', content: '', updatedAt: DateTime.now()),
    );

    await repo.deleteNote(created.id!);
    expect(await repo.getNotes(), isEmpty); // hidden from cache-first list

    await repo.syncNotes(); // deletion acknowledged -> purged
    final raw = await (await db.database).query('notes');
    expect(raw, isEmpty);
  });
}
