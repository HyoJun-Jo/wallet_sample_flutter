import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

/// Register with SNS use case (after code 618 - user not found)
class RegisterWithSnsUseCase implements UseCase<void, RegisterWithSnsParams> {
  final AuthRepository _repository;

  RegisterWithSnsUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, void>> call(RegisterWithSnsParams params) async {
    return await _repository.registerWithSns(
      email: params.email,
      code: params.code,
      snsType: params.loginType.name,
      overage: params.overage,
      agree: params.agree,
      collect: params.collect,
      thirdparty: params.thirdparty,
      advertise: params.advertise,
    );
  }
}

/// Register with SNS parameters
class RegisterWithSnsParams extends Equatable {
  /// User email (from code 618 response)
  final String email;

  /// Verification code (sixcode from code 618 response)
  final String code;

  /// Login type (google, apple, kakao)
  final LoginType loginType;

  /// Age verification (required: over 14 years old)
  final bool overage;

  /// Terms of service agreement (required)
  final bool agree;

  /// Privacy policy agreement (required)
  final bool collect;

  /// Third-party information sharing agreement (required)
  final bool thirdparty;

  /// Marketing consent (optional)
  final bool advertise;

  const RegisterWithSnsParams({
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
