# Offline Notes — Week 5 Mini Assignment

Aplikasi catatan **offline-first** dengan Flutter: preferensi via
SharedPreferences, CRUD persisten via SQLite (sqflite), state management
Riverpod, dirty-flag sync, dan pengujian.

## Fitur

- **Preferensi** — toggle tema gelap/terang + banner *terakhir dibuka*
  (SharedPreferences).
- **CRUD catatan** — repository lokal + Riverpod, daftar diurutkan
  `updated_at` terbaru (sqflite).
- **Offline-first** — cache-first read, dirty flag + `syncNotes()` untuk write,
  aturan konflik LWW terdokumentasi.
- **Bukti mode pesawat** — panduan di `docs/airplane_mode_evidence.md`.
- **Testing** — unit test model + test provider dengan repository palsu.

## Struktur

```
lib/
  models/note.dart              # Model + dirty/deleted flag
  data/
    app_database.dart           # Helper sqflite (schema + index)
    note_repository.dart        # Interface + SyncResult
    local_note_repository.dart  # Implementasi sqflite + syncNotes()
    preferences_service.dart    # SharedPreferences (tema, last opened)
  providers/providers.dart      # Riverpod providers
  ui/
    notes_list_page.dart        # Daftar + badge dirty + tombol Sync
    note_editor_page.dart       # Form create/edit
  main.dart
test/
  note_test.dart                # Unit test model
  notes_provider_test.dart      # Test provider (fake repository)
docs/
  ai_challenge.md               # Prompt, tabel storage, keputusan
  offline_first.md              # Aturan konflik & strategi sync
  airplane_mode_evidence.md     # Panduan screenshot bukti
```

## Menjalankan

```bash
flutter pub get
flutter test
flutter run
```

## Docs

- [AI Challenge — perbandingan storage](docs/ai_challenge.md)
- [Offline-first & aturan konflik](docs/offline_first.md)
- [Bukti mode pesawat](docs/airplane_mode_evidence.md)
