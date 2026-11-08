/// Representasi payload gabungan `notification + data`.
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    required this.route,
    this.data = const <String, dynamic>{},
  });

  final String title;
  final String body;
  final String route;
  final Map<String, dynamic> data;
}
