import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

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

class RegisterWithSnsParams extends Equatable {
  final String email;
  final String code;
  final LoginType loginType;
  final bool overage;
  final bool agree;
  final bool collect;
  final bool thirdparty;
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
