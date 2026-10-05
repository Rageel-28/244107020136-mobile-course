# 05 - Local Storage & Offline-First (Offline Notes)

Proyek aplikasi Flutter untuk praktikum **Minggu 5: Local Storage & Offline-First**. Aplikasi ini menerapkan pola *offline-first* dengan database lokal SQLite, penyimpanan preferensi pengguna via SharedPreferences, arsitektur state management Riverpod, pengambilan data remote dengan strategi *cache-first*, serta pengujian unit/provider.

---

## ?? Struktur Direktori

```text
05-week-5-local-storage-offline-first/
+-- docs/
¦   +-- perbandingan-storage.md   # Komparasi SharedPreferences vs Hive vs sqflite vs Drift
¦   +-- uji-offline.md            # Hasil pengamatan 6 skenario uji offline-first
+-- lib/
¦   +-- data/
¦   ¦   +-- local/                # Skema SQLite, model Note, helper database
¦   ¦   +-- remote/               # Model Post (JSONPlaceholder)
¦   ¦   +-- repositories/         # NoteRepository & PostRepository
¦   ¦   +-- offline_exception.dart# Custom Exception mode offline
¦   ¦   +-- prefs.dart            # Wrapper SharedPreferences
¦   ¦   +-- sync.dart             # Logika sinkronisasi & resolusi konflik (last-write-wins)
¦   +-- pages/                    # Halaman UI (NotesPage, NoteDetailPage, PostsPage, SettingsPage)
¦   +-- providers/                # State management Riverpod (notes, prefs, posts, offline)
¦   +-- widgets/                  # NoteTile, NoteFormDialog
¦   +-- main.dart                 # Entrypoint aplikasi
¦   +-- router.dart               # Konfigurasi GoRouter (deep-linking detail catatan)
+-- test/
¦   +-- note_test.dart            # Pengujian unit & provider test dengan repository palsu
+-- screenshots/                  # Tangkapan layar aplikasi
+-- pubspec.yaml
+-- README.md
```

---

## ?? Fitur & Implementasi Praktikum

1. **Praktikum 1 - Preferensi Pengguna**:
   - Menyimpan tema (Light / Dark) dan timestamp terakhir aplikasi dibuka menggunakan `shared_preferences`.

2. **Praktikum 2 - Database Lokal SQLite**:
   - Model `Note` dengan dukungan field `id`, `title`, `body`, `updated_at`, dan flag `dirty`.
   - Menggunakan `sqflite` dengan tabel `notes` dan `cached_posts`.

3. **Praktikum 3 - UI Catatan Offline**:
   - Antarmuka daftar catatan dengan `FutureProvider` dan `NoteActions` (Riverpod).
   - Dialog tambah & ubah catatan, penghapusan catatan, dan indikator badge jumlah catatan yang belum tersinkron (*dirty*).

4. **Praktikum 4 - Sinkronisasi & Cache-First**:
   - Sinkronisasi catatan lokal yang berstatus *dirty* ke server simulasi dengan aturan konflik *last-write-wins*.
   - Halaman *Posts* dengan strategi *cache-first* (membaca cache lokal terlebih dahulu, lalu me-refresh di background secara asinkron dari endpoint API).
   - Simulasi mode offline via switch pengaturan (*Force Offline*).

5. **Praktikum 5 - Pengujian Otomatis**:
   - Uji unit model `Note` (serialisasi & ketahanan field kosong).
   - Uji provider Riverpod menggunakan `FakeNoteRepository` (skenario sukses & error).
   - Uji logika offline-first (`syncNotes` saat online vs offline, dan resolusi konflik).

6. **Tugas Modifikasi / Pengayaan**:
   - Implementasi navigasi deklaratif menggunakan `go_router` dengan rute `note/:id` ke `NoteDetailPage`.
   - Refactoring UI list item menjadi komponen terpisah `NoteTile` dengan *chip* penanda status sinkronisasi.

---

## ?? Menjalankan Pengujian

Jalankan perintah berikut di dalam direktori proyek:
```bash
flutter test
```
Seluruh 7 skenario pengujian unit dan provider akan diverifikasi.

## ?? Menjalankan Aplikasi

```bash
flutter run
```
Aplikasi mendukung platform Android, iOS, Windows Desktop, dan Web (Chrome/Edge).
