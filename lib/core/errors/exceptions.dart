/// Server exception
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

/// Authentication exception
class AuthException implements Exception {
  final String message;
  final int? code;
  final Map<String, dynamic>? data;

  AuthException({required this.message, this.code, this.data});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Network exception
class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = 'No internet connection'});

  @override
  String toString() => 'NetworkException: $message';
}

/// Wallet exception
class WalletException implements Exception {
  final String message;

  WalletException({required this.message});

  @override
  String toString() => 'WalletException: $message';
}

/// Signing exception
class SigningException implements Exception {
  final String message;

  SigningException({required this.message});

  @override
  String toString() => 'SigningException: $message';
}
