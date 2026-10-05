class OfflineException implements Exception {
  const OfflineException(this.message);
 
  final String message;
 
  @override
  String toString() => 'OfflineException: $message';
}
