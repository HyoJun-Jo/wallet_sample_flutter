import 'package:equatable/equatable.dart';

/// Password reset states
sealed class PasswordResetState extends Equatable {
  const PasswordResetState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PasswordResetInitial extends PasswordResetState {
  const PasswordResetInitial();
}

/// Loading state
class PasswordResetLoading extends PasswordResetState {
  const PasswordResetLoading();
}

/// Error state
class PasswordResetError extends PasswordResetState {
  final String message;

  const PasswordResetError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Verification code sent successfully
class PasswordResetCodeSent extends PasswordResetState {
  final String email;

  const PasswordResetCodeSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Code verified successfully
class PasswordResetCodeConfirmed extends PasswordResetState {
  final String email;
  final String code;

  const PasswordResetCodeConfirmed({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

/// Password reset successful
class PasswordResetSuccess extends PasswordResetState {
  const PasswordResetSuccess();
}
