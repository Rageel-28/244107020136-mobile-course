import '../routes.dart';

final _announcementPattern = RegExp(r'^/pengumuman/([^/?#]+)/?$');

/// Mengubah `data.route` dari FCM menjadi rute internal yang aman.
///
/// Fungsi murni ini sengaja tidak menyentuh Firebase agar bisa diunit-test.
/// Rute yang tidak dikenal dikembalikan ke home supaya payload berbahaya tidak
/// bisa membuka halaman sembarangan.
String routeFromMessage(Map<String, dynamic> data) {
  final raw = (data['route'] ?? '').toString().trim();
  if (raw.isEmpty) return AppRoutes.home;

  final normalized = raw.startsWith('/') ? raw : '/$raw';
  if (normalized == AppRoutes.home) return AppRoutes.home;

  final id = announcementIdFromRoute(normalized);
  if (id == null || id.isEmpty) return AppRoutes.home;

  return AppRoutes.announcement(Uri.decodeComponent(id));
}

/// Mengambil `:id` dari `/pengumuman/:id`, atau `null` bila bukan rute itu.
String? announcementIdFromRoute(String route) {
  final match = _announcementPattern.firstMatch(route);
  return match?.group(1);
}
