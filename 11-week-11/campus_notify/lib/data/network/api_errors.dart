import 'package:dio/dio.dart';

/// Menerjemahkan error teknis menjadi pesan yang aman ditampilkan ke UI.
///
/// UI tidak perlu (dan tidak boleh) menampilkan token atau isi response mentah.
String friendlyApiError(Object error) {
  if (error is! DioException) {
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Koneksi terlalu lama. Periksa jaringan lalu coba lagi.';
    case DioExceptionType.connectionError:
      return 'Tidak ada koneksi internet.';
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';
    case DioExceptionType.badCertificate:
      return 'Sertifikat server tidak valid.';
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;
      if (status == 401) return 'Sesi berakhir. Silakan login ulang.';
      if (status == 403) return 'Anda tidak memiliki akses.';
      if (status == 404) return 'Data tidak ditemukan.';
      if (status != null && status >= 500) {
        return 'Server sedang bermasalah. Coba beberapa saat lagi.';
      }
      return 'Permintaan gagal (${status ?? 'tanpa status'}).';
    case DioExceptionType.unknown:
      return 'Terjadi kesalahan jaringan.';
  }
}
