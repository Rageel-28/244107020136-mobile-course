# Uji Offline-First

Perangkat: Emulator Android Studio (Pixel 10 Pro - Android 17 / API 37)  
Tanggal uji: 5 Oktober 2026  

| No | Skenario | Hasil pengamatan |
|----|----------|------------------|
| 1  | Isi cache posts saat online | Muncul indikator *loading* sejenak untuk mengambil data dari REST API (`jsonplaceholder.typicode.com/posts`), lalu seluruh daftar post (100 item) berhasil tampil dan otomatis tersimpan ke tabel database SQLite `cached_posts` sebagai cache lokal. |
| 2  | Posts saat mode pesawat | Saat beralih ke mode offline, data posts langsung muncul seketika dari cache lokal SQLite tanpa *loading*. Muncul banner oranye bertuliskan *"Mode offline: menampilkan data dari cache lokal"*. Percobaan *pull-to-refresh* menampilkan SnackBar *"Gagal refresh, menampilkan cache"* tanpa menghilangkan data yang sudah tampil. |
| 3  | Tambah 3 catatan offline (badge) | Tiga catatan baru berhasil ditambahkan dan disimpan ke SQLite lokal. Setiap catatan memiliki ikon status awan oranye (`cloud_off` / *dirty*), dan badge counter pada AppBar di pojok kanan atas bertambah menjadi angka **3**. |
| 4  | Sync saat Paksa mode offline | Menekan tombol sinkronisasi (`Icons.sync`) saat fitur "Paksa mode offline" aktif menghasilkan `OfflineException`, menampilkan SnackBar *"Perangkat offline, sinkronisasi ditunda."*. Nilai badge tetap 3 dan data tetap berstatus *dirty*. |
| 5  | Sync saat online | Menekan tombol sinkronisasi saat online berhasil mengunggah data (setelah latensi simulasi 1 detik). Muncul SnackBar *"3 catatan berhasil disinkronkan"*. Ikon status catatan berubah menjadi awan hijau (`cloud_done`) dan badge angka di AppBar otomatis hilang (kembali ke 0). |
| 6  | Refresh background posts | Menerapkan pola *cache-first*: saat membuka halaman posts kembali, data langsung dirender seketika dari cache SQLite tanpa *blocking loader*, kemudian `unawaited(_refreshInBackground)` mengambil data terbaru dari server di latar belakang dan memperbarui tabel cache secara otomatis. |

Aturan konflik yang dipakai: last-write-wins (resolveConflict, updated_at terbaru).
