# AI Challenge — Authentication, Security & FCM

Dokumen ini mencatat prompt, output awal AI, perbaikan manual, dan alasan
teknisnya, sesuai permintaan codelab minggu 6.

## 1. Prompt yang dipakai

```text
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

## 2. Ringkasan output awal AI

Draf pertama AI menghasilkan:

- `PushService` berupa satu kelas besar yang mencampur inisialisasi Firebase,
  penanganan notifikasi, navigasi, dan penyimpanan token.
- Background handler ditulis sebagai **method kelas**.
- `onTokenRefresh` hanya melakukan `debugPrint` token.
- Foreground hanya mengandalkan banner sistem (tanpa local notification).
- Navigasi memakai `Navigator.pushNamed` dan rute hardcoded `'/pengumuman/3'`.
- Token disimpan di `SharedPreferences` dengan alasan "lebih sederhana".
- Seluruh token dicetak penuh ke log untuk keperluan debugging.

## 3. Perbaikan manual yang dilakukan

| Temuan pada draf AI | Perbaikan | Alasan teknis |
| --- | --- | --- |
| Background handler berupa method kelas | Diubah menjadi fungsi top-level `firebaseMessagingBackgroundHandler` dengan `@pragma('vm:entry-point')` | Handler background berjalan di isolate terpisah; method kelas tidak dapat di-resolve dan bisa di-strip compiler |
| `onTokenRefresh` hanya mencetak log | Diteruskan ke `DeviceRepository.registerToken` yang memanggil `POST /devices` | Tanpa pengiriman ulang, backend menyimpan token basi setelah reinstall/clear data |
| Foreground tanpa local notification | Ditambahkan `NotificationPresenter.show` pada `onMessage` | Android/iOS tidak menampilkan banner otomatis saat aplikasi foreground |
| Navigasi hardcoded | Semua rute dipusatkan di `lib/routes.dart` dan dipakai router + parser FCM | Menghindari rute "liar" yang hanya cocok di satu sisi |
| Token di SharedPreferences | Diganti `flutter_secure_storage` lewat `TokenStore` | SharedPreferences tidak terenkripsi |
| Token dicetak penuh | Dihapus; halaman Debug hanya menampilkan 12 karakter pertama | Log dan screenshot dapat bocor ke pihak lain |
| Tidak ada penanganan 401 | Ditambahkan interceptor Dio: refresh sekali, retry sekali, lalu `clear()` | Sesi mati harus memaksa login ulang, bukan gagal berulang |
| Rute dari payload dipakai mentah | Ditambahkan `routeFromMessage` yang memvalidasi pola `/pengumuman/:id` | Mencegah payload membuka rute sembarangan |
| Klik notifikasi lokal saat terminated tidak tertangani | Ditambahkan `getNotificationAppLaunchDetails()` di `NotificationPresenter` | Klik banner lokal saat proses mati tidak masuk ke `onDidReceiveNotificationResponse` |

## 4. Bagian yang berbeda Android 13+ vs iOS

| Aspek | Android 13+ | iOS |
| --- | --- | --- |
| Izin runtime | `POST_NOTIFICATIONS` di manifest + `requestNotificationsPermission()` | `requestPermission()` Firebase / `DarwinInitializationSettings` |
| Channel | Wajib `AndroidNotificationChannel` (id `pengumuman`) | Tidak ada konsep channel |
| Background | `notification` payload ditampilkan sistem; data-only harus diproses manual | APNs key + capability Push Notifications wajib |
| Suara/ikon | `AndroidNotificationDetails` (importance/priority) | `DarwinNotificationDetails` |
| Token null | Umum di emulator tanpa Google Play Services | Butuh APNs token valid |

## 5. Bagian yang tidak boleh mengakses BuildContext

- `firebaseMessagingBackgroundHandler` (isolate terpisah).
- Callback `onTokenRefresh` dan `onMessage` saat dipakai di luar widget tree.
- Callback background `flutter_local_notifications`.

Navigasi selalu dilakukan di layer UI: `onMessageOpenedApp`,
`getInitialMessage`, dan `onDidReceiveNotificationResponse` meneruskan rute ke
`GoRouter` milik aplikasi.

## 6. Keputusan final

Draf AI dipakai sebagai kerangka, tetapi **tidak** diterima apa adanya.
Keputusan yang menyimpang dari saran AI:

1. Token tidak pernah dicetak, bahkan pada mode debug, karena screenshot
   laporan tetap berisiko.
2. Rute divalidasi terhadap daftar pola yang dikenal, bukan diteruskan mentah.
3. Ditambahkan mode demo agar project tetap dapat dinilai tanpa project
   Firebase, dengan penanda jelas di UI bahwa FCM belum aktif.

Bukti perilaku nyata ada pada `docs/pengujian-app-state.md` dan folder
`screenshots/`.
