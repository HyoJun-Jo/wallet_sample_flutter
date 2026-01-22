import 'package:equatable/equatable.dart';

/// Email registration states
sealed class EmailRegistrationState extends Equatable {
  const EmailRegistrationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class EmailRegistrationInitial extends EmailRegistrationState {
  const EmailRegistrationInitial();
}

/// Loading state
class EmailRegistrationLoading extends EmailRegistrationState {
  const EmailRegistrationLoading();
}

/// Email is available for registration
class EmailAvailable extends EmailRegistrationState {
  final String email;

  const EmailAvailable({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Email is not available (already registered)
class EmailNotAvailable extends EmailRegistrationState {
  final String email;

  const EmailNotAvailable({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Verification code sent
class VerificationCodeSent extends EmailRegistrationState {
  final String email;

  const VerificationCodeSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Code verified successfully
class CodeVerified extends EmailRegistrationState {
  final String email;
  final String code;

  const CodeVerified({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

/// Password initialized successfully
class PasswordInitialized extends EmailRegistrationState {
  final String email;
  final String code;

  const PasswordInitialized({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

/// Registration successful
class EmailRegistrationSuccess extends EmailRegistrationState {
  final String email;

  const EmailRegistrationSuccess({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Registration error
class EmailRegistrationError extends EmailRegistrationState {
  final String message;

  const EmailRegistrationError({required this.message});

  @override
  List<Object?> get props => [message];
}
