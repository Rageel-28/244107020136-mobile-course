import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Thin wrapper around sqflite that owns the database schema.
class AppDatabase {
  AppDatabase({this.databaseName = 'offline_notes.db'});

  final String databaseName;
  static const int schemaVersion = 1;

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    // `:memory:` (and other absolute/special paths) must be used verbatim;
    // only plain file names are resolved against the platform databases dir.
    final path = databaseName == inMemoryDatabasePath
        ? inMemoryDatabasePath
        : p.join(await getDatabasesPath(), databaseName);
    return openDatabase(
      path,
      version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            is_dirty INTEGER NOT NULL DEFAULT 1,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC)',
        );
      },
    );
  }

  /// Overrides the active database. Used by tests with an in-memory DB.
  set database(Database value) => _db = value;

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
