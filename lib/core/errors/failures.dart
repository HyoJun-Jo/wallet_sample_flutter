import 'package:equatable/equatable.dart';

/// Failure base class
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error'});
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Wallet failure
class WalletFailure extends Failure {
  const WalletFailure({required super.message, super.code});
}

/// Signing failure
class SigningFailure extends Failure {
  const SigningFailure({required super.message, super.code});
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}
