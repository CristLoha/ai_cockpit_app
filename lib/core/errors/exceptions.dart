class RateLimitException implements Exception {
  final Duration retryAfter;
  RateLimitException(this.retryAfter);
  @override
  String toString() =>
      'Rate limit exceeded. Please wait ${retryAfter.inSeconds} seconds.';
}

class GuestLimitExceededException implements Exception {
  @override
  String toString() =>
      'Batas penggunaan tamu tercapai. Silakan Sign In untuk melanjutkan.';
}
