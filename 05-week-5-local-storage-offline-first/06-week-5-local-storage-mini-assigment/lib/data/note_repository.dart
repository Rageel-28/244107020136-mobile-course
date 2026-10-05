import '../models/note.dart';

/// Result of a [NoteRepository.syncNotes] run, used by the UI to show
/// feedback (e.g. "3 catatan tersinkron").
class SyncResult {
  const SyncResult({required this.synced, required this.failed});

  final int synced;
  final int failed;

  bool get hasChanges => synced > 0;
}

/// Abstraction over persistent note storage.
///
/// The UI depends on this interface (not the concrete sqflite class) so it can
/// be swapped for a fake in tests and for a remote-backed implementation in a
/// real offline-first setup.
abstract class NoteRepository {
  /// Cache-first read: returns locally stored notes, newest [Note.updatedAt]
  /// first. This is what the UI renders while offline.
  Future<List<Note>> getNotes();

  Future<Note?> getNote(int id);

  /// Creates a note and marks it dirty. Returns the stored note with its id.
  Future<Note> createNote(Note note);

  /// Updates a note and marks it dirty.
  Future<Note> updateNote(Note note);

  /// Soft-deletes a note (sets [Note.isDeleted]) and marks it dirty so the
  /// deletion propagates on the next sync.
  Future<void> deleteNote(int id);

  /// Pushes all dirty rows to the remote backend.
  ///
  /// Contract:
  ///  - Successfully pushed rows become clean ([Note.isDirty] = false).
  ///  - Soft-deleted rows are purged locally after being acknowledged.
  ///  - Failed rows stay dirty and are retried on the next call.
  Future<SyncResult> syncNotes();
}
