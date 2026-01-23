import 'package:equatable/equatable.dart';
import '../../../../core/auth/entities/auth_entities.dart';

/// SNS registration state base class
sealed class SnsRegistrationState extends Equatable {
  const SnsRegistrationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SnsRegistrationInitial extends SnsRegistrationState {
  const SnsRegistrationInitial();
}

/// Loading state
class SnsRegistrationLoading extends SnsRegistrationState {
  const SnsRegistrationLoading();
}

/// Registration success state
class SnsRegistrationSuccess extends SnsRegistrationState {
  final String email;
  final LoginType loginType;

  const SnsRegistrationSuccess({
    required this.email,
    required this.loginType,
  });

  @override
  List<Object?> get props => [email, loginType];
}

/// Registration error state
class SnsRegistrationError extends SnsRegistrationState {
  final String message;

  const SnsRegistrationError({required this.message});

  @override
  List<Object?> get props => [message];
}
