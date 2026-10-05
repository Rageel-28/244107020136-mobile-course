import 'package:sqflite/sqflite.dart';

import '../models/note.dart';
import 'app_database.dart';
import 'note_repository.dart';

/// Signature for the "remote" push operation used during sync.
///
/// In this offline-first assignment there is no real backend, so the default
/// implementation is a no-op that always succeeds. A real app would POST the
/// note here (or use a push API) and throw on failure.
typedef RemotePush = Future<void> Function(Note note);

/// sqflite-backed implementation of [NoteRepository].
class LocalNoteRepository implements NoteRepository {
  LocalNoteRepository({AppDatabase? database, RemotePush? remotePush})
      : _database = database ?? AppDatabase(),
        _remotePush = remotePush ?? _noopPush;

  final AppDatabase _database;
  final RemotePush _remotePush;

  static Future<void> _noopPush(Note note) async {}

  Future<Database> get _db => _database.database;

  @override
  Future<List<Note>> getNotes() async {
    final db = await _db;
    final rows = await db.query(
      'notes',
      where: 'is_deleted = 0',
      orderBy: 'updated_at DESC, id DESC',
    );
    return rows.map((row) => Note.fromMap(row)).toList();
  }

  @override
  Future<Note?> getNote(int id) async {
    final db = await _db;
    final rows = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  @override
  Future<Note> createNote(Note note) async {
    final db = await _db;
    final now = DateTime.now();
    final toInsert = note.copyWith(
      updatedAt: now,
      createdAt: note.createdAt ?? now,
      isDirty: true,
    );
    final id = await db.insert('notes', toInsert.toMap());
    return toInsert.copyWith(id: id);
  }

  @override
  Future<Note> updateNote(Note note) async {
    assert(note.id != null, 'updateNote requires a persisted note id');
    final db = await _db;
    final updated = note.copyWith(updatedAt: DateTime.now(), isDirty: true);
    await db.update(
      'notes',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
    return updated;
  }

  @override
  Future<void> deleteNote(int id) async {
    final db = await _db;
    await db.update(
      'notes',
      {
        'is_deleted': 1,
        'is_dirty': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<SyncResult> syncNotes() async {
    final db = await _db;
    final dirtyRows = await db.query('notes', where: 'is_dirty = 1');

    var synced = 0;
    var failed = 0;

    for (final row in dirtyRows) {
      final note = Note.fromMap(row);
      try {
        await _remotePush(note);
        if (note.isDeleted) {
          // Deletion acknowledged by remote -> purge locally.
          await db.delete('notes', where: 'id = ?', whereArgs: [note.id]);
        } else {
          await db.update(
            'notes',
            {'is_dirty': 0},
            where: 'id = ?',
            whereArgs: [note.id],
          );
        }
        synced++;
      } catch (_) {
        // Leave the row dirty so it is retried on the next sync.
        failed++;
      }
    }

    return SyncResult(synced: synced, failed: failed);
  }
}
