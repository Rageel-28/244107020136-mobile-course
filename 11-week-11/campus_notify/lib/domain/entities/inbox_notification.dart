/// Item notifikasi yang masuk ke daftar belum dibaca (unread inbox).
///
/// Ketika notifikasi ini dibaca/diklik oleh pengguna, item akan dihapus dari
/// state inbox dan angka badge pada ikon notifikasi otomatis berkurang.
class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.announcementId,
    required this.title,
    required this.body,
    required this.route,
    required this.receivedAt,
  });

  final String id;
  final String announcementId;
  final String title;
  final String body;
  final String route;
  final DateTime receivedAt;
}
