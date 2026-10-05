# Offline-First Design & Aturan Konflik

## 1. Prinsip

Aplikasi **selalu** membaca dan menulis ke SQLite lokal terlebih dahulu. Jaringan
tidak pernah menjadi syarat untuk operasi utama (cache-first read, local-first
write). Sinkronisasi ke "remote" bersifat *best-effort* dan dijalankan eksplisit
tombol **Sync** (atau otomatis saat koneksi kembali, di masa depan).

```
        baca                         tulis
UI ───────────► SQLite (cache)   UI ──────► SQLite (is_dirty = 1)
                    ▲                             │
                    └──────── syncNotes() ◄───────┘
                              (push dirty rows)
```

## 2. Cache-First untuk Data Bacaan

- `NotesController.build()` selalu memanggil `repository.getNotes()` dari SQLite.
- Urutan: `ORDER BY updated_at DESC, id DESC` (terbaru di atas).
- Tidak ada network call pada jalur baca → daftar tetap tampil **saat mode pesawat**.
- Setelah setiap mutasi, UI di-refresh dari cache (bukan dari respons server).

## 3. Dirty Flag untuk Tulisan

Setiap write lokal menandai baris:

| Operasi | Aksi lokal |
|---|---|
| Create | `INSERT` dengan `is_dirty = 1` |
| Update | `UPDATE` konten + `updated_at = now`, `is_dirty = 1` |
| Delete | `UPDATE is_deleted = 1, is_dirty = 1, updated_at = now` (soft delete) |

`syncNotes()`:
1. Ambil semua baris `WHERE is_dirty = 1`.
2. Untuk tiap baris, panggil `remotePush(note)`.
   - **Sukses, bukan deleted** → `is_dirty = 0`.
   - **Sukses, deleted** → `DELETE` baris lokal (remote sudah mengakui).
   - **Gagal** → biarkan `is_dirty = 1` (akan dicoba lagi pada sync berikutnya).
3. Kembalikan `SyncResult(synced, failed)` untuk umpan balik UI.

Karena remote di project ini adalah **no-op** (`_noopPush`), sync selalu sukses —
cukup untuk mendemonstrasikan perubahan badge dirty. `RemotePush` adalah
`typedef` yang bisa diganti dengan HTTP call nyata tanpa mengubah repository.

## 4. Aturan Konflik (Eksplisit)

Konteks: satu pengguna, perubahan bisa terjadi di dua tempat (lokal offline vs
remote). Kebijakan yang dipilih adalah **Last-Write-Wins (LWW) dengan timestamp
yang dibuat klien.**

**Aturan 1 — Delete vs Update (delete menang).**
Jika sebuah catatan dihapus lokal (soft delete, dirty) dan remote ternyata lebih
baru, penghapusan tetap dikirim. Rasional: pengguna sengaja menghapus; menghidupkan
kembali data yang sudah dibuang lebih mengganggu daripada kehilangan satu edit.
Delete diakui remote → baris lokal dipurge.

**Aturan 2 — Update vs Update (updated_at terbaru menang).**
Bila baris lokal dirty dan remote juga berubah, bandingkan `updated_at`:
- `local.updated_at >= remote.updated_at` → push lokal, timpa remote.
- `local.updated_at < remote.updated_at` → tarik remote, panggil
  `is_dirty = 0` (resolusi "server wins" untuk konflik lebih tua).

**Aturan 3 — Create dengan id bentrok.**
Karena id bersifat autoincrement lokal, bentrok id tidak mungkin pada skenario
single-user. Bila nanti multi-device, id lokal diganti dengan **UUID** agar tidak
pernah bentrok; aturan LWW di atas tetap berlaku.

**Aturan 4 — Kegagalan jaringan bukan konflik.**
Push gagal (timeout/offline) **tidak** mengubah `is_dirty`. Baris tinggal dirty
dan dicoba lagi; tidak ada resolusi yang dilakukan sampai remote benar-benar
merespons.

> Batasan saat ini: implementasi `syncNotes()` mengasumsikan remote menerima
> tulisan apa pun (`_noopPush`). Aturan 2–3 didokumentasikan sebagai kontrak
> untuk implementasi remote nyata; comparator-nya sudah tersedia lewat
> `Note.updatedAt` dan `NoteRepository.syncNotes()`.

## 5. Preferensi (SharedPreferences)

- `dark_mode` (bool) — dibaca saat startup agar tema tidak berkedip.
- `last_opened` (epoch millis) — ditulis di `main()` setiap peluncuran dan
  ditampilkan sebagai banner "Terakhir dibuka".

Keduanya **bukan** data domain dan tidak ikut sync.
