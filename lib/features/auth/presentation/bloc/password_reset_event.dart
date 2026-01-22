import 'package:equatable/equatable.dart';

/// Password reset events
sealed class PasswordResetEvent extends Equatable {
  const PasswordResetEvent();

  @override
  List<Object?> get props => [];
}

/// Request verification code for password reset
class PasswordResetCodeRequested extends PasswordResetEvent {
  final String email;

  const PasswordResetCodeRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Verify the code
class PasswordResetCodeVerified extends PasswordResetEvent {
  final String email;
  final String code;

  const PasswordResetCodeVerified({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

/// Submit new password
class PasswordResetSubmitted extends PasswordResetEvent {
  final String email;
  final String password;
  final String code;

  const PasswordResetSubmitted({
    required this.email,
    required this.password,
    required this.code,
  });

  @override
  List<Object?> get props => [email, password, code];
}
