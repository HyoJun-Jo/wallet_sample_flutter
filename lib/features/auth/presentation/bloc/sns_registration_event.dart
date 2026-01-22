import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_entities.dart';

/// SNS registration event base class
sealed class SnsRegistrationEvent extends Equatable {
  const SnsRegistrationEvent();

  @override
  List<Object?> get props => [];
}

/// SNS registration submit request
class SnsRegistrationSubmitted extends SnsRegistrationEvent {
  final String email;
  final String code;
  final LoginType loginType;
  final bool overage;
  final bool agree;
  final bool collect;
  final bool thirdparty;
  final bool advertise;

  const SnsRegistrationSubmitted({
    required this.email,
    required this.code,
    required this.loginType,
    this.overage = true,
    this.agree = true,
    this.collect = true,
    this.thirdparty = true,
    this.advertise = false,
  });

  @override
  List<Object?> get props => [
        email,
        code,
        loginType,
        overage,
        agree,
        collect,
        thirdparty,
        advertise,
      ];
}
