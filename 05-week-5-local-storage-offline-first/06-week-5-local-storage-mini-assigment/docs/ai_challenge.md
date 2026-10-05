# AI Challenge — Pemilihan Strategy Penyimpanan Lokal

Dokumen ini memuat **prompt AI yang dipakai**, **tabel perbandingan storage**,
**keputusan final**, dan **alasan teknis** untuk mini project *Offline Notes*.

---

## 1. Prompt yang Digunakan

> Saya membangun aplikasi catatan offline-first dengan Flutter. Saya perlu
> menyimpan tiga jenis data yang berbeda:
>
> 1. **Preferensi** (toggle tema gelap/terang dan timestamp *terakhir dibuka*).
> 2. **Catatan** (CRUD penuh, punya `id`, `title`, `content`, `created_at`,
>    `updated_at`, `is_dirty`, `is_deleted`; daftar harus diurutkan `updated_at`
>    terbaru; jumlah catatan bisa ratusan).
> 3. **Metadata sinkronisasi** (status dirty per-baris, agar tulisan offline
>    bisa di-push saat kembali online).
>
> Kandidat teknologi: **SharedPreferences**, **Hive**, **SQLite (sqflite)**,
> dan **flutter_secure_storage**.
>
> Tolong buatkan **tabel perbandingan** berdasarkan kriteria: tipe data yang
> cocok, kecepatan baca/tulis, query & sorting, relasi, effort integrasi, dukungan
> offline-first, dan keamanan. Lalu **rekomendasikan** kombinasi mana yang
> paling tepat untuk tiap jenis data, beserta alasan teknisnya.

---

## 2. Tabel Perbandingan Storage

| Kriteria | SharedPreferences | Hive | SQLite (sqflite) | flutter_secure_storage |
|---|---|---|---|---|
| **Tipe data cocok** | Key-value primitif (bool, int, String, List/String) | Object/box (NoSQL key-value) | Tabel relasional, baris terstruktur | Secret/keychain (String) |
| **Kecepatan baca/tulis** | Sangat cepat untuk data kecil | Cepat (in-memory + box) | Cepat, sedikit overhead query | Lambat (crypto + platform channel) |
| **Query & sorting** | Tidak ada | Terbatas (butuh index manual) | `ORDER BY`, `WHERE`, `INDEX` bawaan | Tidak ada |
| **Relasi** | Tidak | Tidak | Ya (foreign key, JOIN) | Tidak |
| **Effort integrasi** | Sangat rendah (1 perintah) | Rendah–sedang (adapter/type adapter) | Sedang (schema, migration, helper) | Rendah, tapi hanya untuk rahasia |
| **Dukungan offline-first** | Hanya preferensi; tidak ada transaksi/dirty tracking | Bisa, tapi dirty tracking manual | Kuat: transaksi, `updated_at`, `is_dirty`, `is_deleted` | Tidak relevan untuk data domain |
| **Keamanan** | Tidak terenkripsi | Opsional (`HiveAesCipher`) | Tidak terenkripsi (perlu SQLCipher) | Terenkripsi (Keystore/Keychain) |

---

## 3. Keputusan Final

| Jenis Data | Storage Terpilih | Alasan Teknis |
|---|---|---|
| **Preferensi** (tema, last opened) | **SharedPreferences** | Data key-value primitif berjumlah sedikit. API `setBool`/`getBool`/`setInt`/`getInt` paling sederhana; tanpa schema/migration. Membaca langsung di `main()` sebelum `runApp` untuk menghindari flash tema. |
| **Catatan (CRUD)** | **SQLite (sqflite)** | Butuh query terurut (`ORDER BY updated_at DESC`), filtering soft-delete (`WHERE is_deleted = 0`), dan **index** pada `updated_at`. SQLite adalah satu-satunya kandidat yang mendukung sorting + index secara efisien dan aman untuk ratusan+ baris. |
| **Metadata sinkronisasi** | **SQLite (sqflite)** — kolom `is_dirty` / `is_deleted` per baris | Dirty flag harus **transaksional dan menempel pada baris catatan**. Menyimpannya terpisah (mis. di SharedPreferences/Hive) berisiko desync dengan data catatan. Satu tabel = satu sumber kebenaran. |
| **Secret (opsional)** | flutter_secure_storage | *Tidak dipakai di project ini* karena tidak ada token/kredensial yang disimpan. Dicatat sebagai pilihan jika nanti ada autentikasi. |

**Kesimpulan:** arsitektur *polyglot persistence* sederhana — **SharedPreferences**
untuk preferensi, **sqflite** untuk semua data domain + metadata sync.

---

## 4. Alasan Teknis (Ringkas)

1. **Right tool for the right job.** Preferensi tidak butuh query/relasi;
   memaksakan SQLite hanya menambah kode. Sebaliknya catatan butuh sorting &
   index yang tidak dimiliki SharedPreferences/Hive secara natural.
2. **Satu sumber kebenaran untuk sync.** `is_dirty` hidup di baris yang sama
   dengan data, sehingga operasi `UPDATE ... SET is_dirty = 1` atomik dan tidak
   mungkin "yatim" bila proses crash di tengah.
3. **Skalabilitas baca.** Index `idx_notes_updated_at` membuat `getNotes()`
   tetap O(log n) saat jumlah catatan tumbuh; SharedPreferences harus
   load-decode-sort seluruh blob di memori tiap kali.
4. **Offline-first alami.** sqflite mendukung transaksi dan soft-delete, yang
   menjadi fondasi aturan konflik pada `docs/offline_first.md`.
5. **Kemudahan tes.** Repository diabstraksi (`NoteRepository`), sehingga test
   provider memakai fake in-memory tanpa menyentuh platform — lihat
   `test/notes_provider_test.dart`.

> Catatan: keputusan ini akan ditinjau ulang bila muncul kebutuhan enkripsi
> (→ SQLCipher) atau sinkronisasi real-time lintas perangkat (→ backend + tabel
> sync_log/version vector).
