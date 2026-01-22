import 'package:equatable/equatable.dart';

/// Email registration events
sealed class EmailRegistrationEvent extends Equatable {
  const EmailRegistrationEvent();

  @override
  List<Object?> get props => [];
}

/// Check email availability
class EmailCheckRequested extends EmailRegistrationEvent {
  final String email;

  const EmailCheckRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Request verification code
class VerificationCodeRequested extends EmailRegistrationEvent {
  final String email;

  const VerificationCodeRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Verify the code
class CodeVerificationRequested extends EmailRegistrationEvent {
  final String email;
  final String code;

  const CodeVerificationRequested({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

/// Initialize password
class PasswordInitRequested extends EmailRegistrationEvent {
  final String email;
  final String password;
  final String code;

  const PasswordInitRequested({
    required this.email,
    required this.password,
    required this.code,
  });

  @override
  List<Object?> get props => [email, password, code];
}

/// Submit email registration
class EmailRegistrationSubmitted extends EmailRegistrationEvent {
  final String email;
  final String password;
  final String code;
  final bool overage;
  final bool agree;
  final bool collect;
  final bool thirdparty;
  final bool advertise;

  const EmailRegistrationSubmitted({
    required this.email,
    required this.password,
    required this.code,
    this.overage = true,
    this.agree = true,
    this.collect = true,
    this.thirdparty = true,
    this.advertise = false,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        code,
        overage,
        agree,
        collect,
        thirdparty,
        advertise,
      ];
}
