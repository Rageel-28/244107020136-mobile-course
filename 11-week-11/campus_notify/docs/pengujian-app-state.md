# Pengujian Tiga App State

Pengujian dilakukan pada emulator Android (Pixel 10 Pro, Android dengan Google
Play Services) memakai build debug `app-debug.apk`.

Payload uji (sama untuk ketiga state):

```json
{
  "notification": {
    "title": "Jadwal kuliah berubah",
    "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
  },
  "data": { "route": "/pengumuman/3", "id": "3" }
}
```

Karena `google-services.json` belum tersedia, pengujian memakai mode demo yang
menjalankan jalur kode yang sama: `NotificationPresenter` menampilkan banner,
`payload` berisi `data.route`, dan `onOpenRoute` meneruskan ke GoRouter.

## Matriks hasil

| No | State | Langkah | Hasil yang diharapkan | Hasil aktual | Bukti |
| --- | --- | --- | --- | --- | --- |
| 1 | Foreground | Aplikasi terbuka di halaman Debug, tekan `Foreground` | Banner lokal muncul, klik membuka `/pengumuman/3` | Banner muncul di shade dan snackbar aksi `Buka` tampil; klik membuka halaman pengumuman | `05-foreground-banner.png` |
| 2 | Background | Tekan `Background (5 detik)`, tekan Home, tunggu banner | Banner sistem muncul, klik membuka rute tujuan | Banner muncul di shade; klik membuka `/pengumuman/3` | `06-background-banner.png`, `06b-background-deep-link.png` |
| 3 | Terminated | Tekan `Background (5 detik)`, tutup proses lewat Recents, tunggu banner, klik banner | Proses mati, klik membuka aplikasi di rute tujuan | `pidof` kosong sebelum klik, PID baru muncul setelah klik, aplikasi langsung di `/pengumuman/3` | `07-terminated-notification-tray.png`, `08-terminated-deep-link.png` |

## Catatan teknis

- Foreground: `FirebaseMessaging.onMessage` tidak menampilkan banner otomatis,
  sehingga `NotificationPresenter.show` dipanggil manual dengan payload
  `data.route`.
- Background: klik banner diteruskan oleh `onDidReceiveNotificationResponse`
  (aplikasi masih hidup) ke `GoRouter.go`.
- Terminated: klik banner lokal dibaca lewat
  `getNotificationAppLaunchDetails()` saat `initialize`, sehingga rute tetap
  dipulihkan walaupun `onDidReceiveNotificationResponse` tidak terpanggil.
  Untuk FCM sungguhan jalur ini dilengkapi `getInitialMessage()`.
- Topik `pengumuman-kampus` disubscribe saat inisialisasi push service dan
  dapat diuji subscribe/unsubscribe dari halaman Debug.
- Token perangkat hanya ditampilkan terpotong 12 karakter pada halaman Debug.

## Perintah verifikasi

```bash
flutter analyze   # No issues found
flutter test      # 16 test lulus
flutter build apk --debug
```

## Catatan untuk FCM sungguhan

Langkah yang sama berlaku setelah `google-services.json` dipasang, dengan
tambahan:

1. Kirim campaign dari Firebase Console ke aplikasi Android.
2. Uji ketiga state memakai payload gabungan `notification + data`.
3. Pastikan `onTokenRefresh` mengirim ulang token ke `POST /devices` setelah
   clear data/reinstall.
