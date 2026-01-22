import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_entities.dart';

/// Login state base class
sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LoginInitial extends LoginState {
  const LoginInitial();
}

/// Loading state
class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Authenticated state
class LoginAuthenticated extends LoginState {
  final AuthCredentials credentials;

  const LoginAuthenticated({required this.credentials});

  @override
  List<Object?> get props => [credentials];
}

/// Unauthenticated state
class LoginUnauthenticated extends LoginState {
  const LoginUnauthenticated();
}

/// Error state
class LoginError extends LoginState {
  final String message;

  const LoginError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Email registration required state (code 602 - user not registered)
class EmailRegistrationRequired extends LoginState {
  final String email;

  const EmailRegistrationRequired({required this.email});

  @override
  List<Object?> get props => [email];
}

/// SNS registration required state (code 618 - user not found)
class SnsRegistrationRequired extends LoginState {
  final String email;
  final String token;
  final String sixcode;
  final String language;
  final int timeout;
  final LoginType loginType;

  const SnsRegistrationRequired({
    required this.email,
    required this.token,
    required this.sixcode,
    required this.language,
    required this.timeout,
    required this.loginType,
  });

  @override
  List<Object?> get props => [email, token, sixcode, language, timeout, loginType];
}
