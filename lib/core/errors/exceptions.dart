class GuestLimitExceededException implements Exception {
  @override
  String toString() =>
      'Batas penggunaan tamu tercapai. Silakan Sign In untuk melanjutkan.';
}

class ServerException implements Exception {
  final String message;

  ServerException(this.message);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  @override
  String toString() =>
      'Tidak ada koneksi internet. Periksa kembali jaringan Anda.';
}


class AnalysisException implements Exception {
  final String message;

  AnalysisException(this.message);

  @override
  String toString() => message;
}
