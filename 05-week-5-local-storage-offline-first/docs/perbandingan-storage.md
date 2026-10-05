# Perbandingan Solusi Penyimpanan Lokal Flutter: SharedPreferences vs Hive vs sqflite vs Drift

Dokumen ini membandingkan empat opsi *local persistence* pada Flutter untuk dua kebutuhan spesifik:
1. **Preferensi Tema & Konfigurasi** (Data *key-value* sederhana berukuran kecil).
2. **CRUD Catatan Offline** (Data terstruktur yang dapat bertumbuh hingga ribuan catatan, memerlukan pencarian, penyortiran, dan sinkronisasi).

---

## 1. Matriks Perbandingan Berdasarkan Kriteria

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift (Moor) |
|---|---|---|---|---|
| **Kompleksitas Query** | Sangat Rendah. Hanya *get/set* berbasis key. Tidak ada *sorting*, *filtering*, atau pagination. | Rendah–Sedang. Query filter manual via iterasi koleksi di memori. Kurang optimal untuk query multi-kondisi kompleks. | Tinggi. Mendukung SQL standar penuh (SELECT, WHERE, ORDER BY, GROUP BY, LIMIT/OFFSET, Subqueries, Full-Text Search FTS). | Sangat Tinggi. SQL penuh dengan *Fluent Dart API* atau SQL murni yang divalidasi saat kompilasi (*type-safe*). |
| **Kebutuhan Relasi** | Tidak mendukung relasi (*flat key-value*). | Tidak ada relasi bawaan (harus mengelola ID relasi secara manual di kode aplikasi). | Mendukung penuh Foreign Keys, JOIN (INNER/LEFT), dan CASCADE DELETE. | Mendukung penuh Foreign Keys, JOIN otomatis antar tabel, dan relasi *type-safe*. |
| **Reaktivitas (Stream)** | Tidak reaktif secara bawaan (harus dibungkus manual via Riverpod StateNotifier / ValueNotifier). | Semi-reaktif (mendukung `watch()` pada box/key tertentu via Hive Streams). | Tidak reaktif secara native (perlu trigger invalidate manual atau wrapper stream sendiri). | **Sangat Reaktif (Native Streams)**. Menyediakan `watch()` otomatis yang memancarkan stream data setiap kali tabel terkait berubah. |
| **Type-Safety** | Lemah. Mengandalkan fungsi primitif (`getBool`, `getString`). Rawan runtime typo key. | Sedang. Memerlukan *TypeAdapter* dan code generation (`build_runner`), namun query in-memory tidak type-safe secara skema. | Rendah. Berbasis `Map<String, Object?>` dan raw SQL string. Error salah nama kolom baru ketahuan saat runtime. | **Sangat Tinggi**. Skema dan query diverifikasi saat compile-time. Mendukung data class otomatis yang *null-safe* dan *type-safe*. |
| **Ukuran Boilerplate** | Sangat Minim. Langsung pakai tanpa skema atau code-generation. | Sedang. Butuh registrasi TypeAdapter dan anotasi model. | Sedang–Tinggi. Perlu menulis DDL manual, *raw string queries*, serta fungsi `toMap` dan `fromMap`. | Tinggi di awal. Butuh anotasi skema, setup file Drift, dan menjalankan `build_runner`. Namun minim boilerplate di repository karena query sudah *generated*. |
| **Kemudahan Testing** | Sangat Mudah. Sudah tersedia `setMockInitialValues` dari paket pengujian resmi. | Mudah–Sedang. Perlu inisialisasi temp directory atau mock box saat unit test. | Sedang–Tinggi. Perlu FFI (`sqflite_common_ffi`) atau *fake repository* berbasis mock in-memory database. | Sangat Mudah. Menyediakan `NativeDatabase.memory()` bawaan khusus untuk unit test tanpa perlu mock manual. |

---

## 2. Skema Penyimpanan untuk 1000+ Catatan

### A. Skema Relasional (sqflite & Drift)

Untuk menangani 1000+ catatan secara efisien, skema SQL memanfaatkan *B-Tree Indexing* dan *pagination* agar tidak membebani konsumsi memori (RAM):

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 0
);

-- Index krusial untuk performa query 1000+ data
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_notes_dirty ON notes(dirty);
```

**Kelebihan pada Skala 1000+ Catatan:**
- Mendukung pagination via `LIMIT 20 OFFSET 0` (hanya memuat data yang tampak di layar).
- Penyortiran catatan terbaru dan filtering catatan *dirty* (belum sinkron) berjalan dalam waktu $O(\log N)$ berkat index.
- Data disimpan di disk (bukan seluruhnya di RAM).

---

### B. Skema Kotak Objek / NoSQL (Hive)

Hive menyimpan objek ke dalam file biner (*Box*):

```dart
@HiveType(typeId: 1)
class NoteHive extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String body;

  @HiveField(3)
  late DateTime updatedAt;

  @HiveField(4)
  late bool dirty;
}
```

**Kelebihan & Keterbatasan pada Skala 1000+ Catatan:**
- Hive sangat cepat dalam pembacaan dan penulisan *key-value*.
- Namun secara default, Hive memuat seluruh *keys* atau seluruh data box ke dalam RAM. Jika catatan memiliki `body` yang panjang dan mencapai ribuan catatan, konsumsi memori perangkat akan meningkat.
- Pengurutan dan pencarian harus dilakukan via iterasi Dart di memori: `box.values.where(...).toList()..sort(...)`.

---

### C. Skema SharedPreferences (Anti-Pattern untuk Kumpulan Data)

Jika dipaksakan untuk 1000 catatan, SharedPreferences hanya dapat menyimpan string JSON raksasa:
```json
// Key: "notes_data"
"[{\"id\":1,\"title\":\"A\",...}, {\"id\":2,\"title\":\"B\",...}, ... 1000 item]"
```

**Kelemahan Fatal:**
- Setiap kali menambah, mengedit, atau menghapus **1 catatan**, seluruh 1000 item harus di-serialize/deserialize ulang ke string JSON dan ditulis ulang ke file XML (Android) / plist (iOS).
- Rawan *ANR (Application Not Responding)* dan konsumsi CPU tinggi.

---

## 3. Analisis Trade-Off untuk 1000+ Catatan

| Pilihan | Keunggulan Utama | Trade-Off / Titik Lemah |
|---|---|---|
| **SharedPreferences** | Tanpa dependensi rumit, instan digunakan. | **Tidak layak**. Tidak ada indexing, serialisasi JSON 1000 objek memakan CPU & memblokir thread. |
| **Hive** | Kecepatan I/O biner sangat tinggi, sintaks Dart murni. | Seluruh data/indeks disimpan di RAM; query pencarian & penyortiran kompleks lambat karena dihitung manual di CPU Dart. |
| **sqflite** | Standar industri (SQLite), hemat RAM berkat cursor & indexing, handal untuk ACID transactions. | Rentan kesalahan pengetikan nama kolom/query (raw string SQL), tidak reaktif otomatis (butuh invalidate manual). |
| **Drift** | Sangat aman (*compile-time type safety*), live stream query otomatis, testing in-memory sangat mudah. | Memerlukan *code generation* (`build_runner`) dan ukuran binary sedikit lebih besar. |

---

## 4. Rekomendasi Final

| Kebutuhan | Rekomendasi Terpilih | Alasan Utama |
|---|---|---|
| **Preferensi Tema & Waktu Terbuka** | **SharedPreferences** | Nilainya hanya berupa tipe primitif (`bool` untuk dark mode, `String` untuk ISO timestamp). Sangat ringan, tidak butuh skema, tidak ada dependensi database, dan sinkron langsung dengan preferensi native OS. |
| **CRUD Catatan Offline (1000+ Data)** | **sqflite** *(atau **Drift** untuk skala enterprise)* | Catatan memerlukan query terurut (`updated_at DESC`), filtering status sinkronisasi (`dirty = 1`), serta pagination agar memori hemat. Mesin SQLite bawaan OS menjamin integritas transaksi ACID, indexing cepat, dan pemrosesan query tanpa membebani memori aplikasi. |
