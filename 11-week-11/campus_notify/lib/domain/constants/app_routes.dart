/// Satu sumber kebenaran untuk semua rute aplikasi.
///
/// Deep link dari FCM dan konfigurasi GoRouter memakai konstanta yang sama
/// supaya tidak ada rute "liar" yang hanya cocok di salah satu sisi.
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const debug = '/debug';
  static const announcementPattern = '/pengumuman/:id';

  static String announcement(String id) => '/pengumuman/$id';
}
