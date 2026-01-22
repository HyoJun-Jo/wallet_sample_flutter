import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Register with email parameters
class RegisterWithEmailParams extends Equatable {
  final String email;
  final String password;
  final String code;
  final bool overage;
  final bool agree;
  final bool collect;
  final bool thirdparty;
  final bool advertise;

  const RegisterWithEmailParams({
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

/// Register with email use case
class RegisterWithEmailUseCase
    implements UseCase<void, RegisterWithEmailParams> {
  final AuthRepository _repository;

  RegisterWithEmailUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, void>> call(RegisterWithEmailParams params) async {
    return await _repository.registerWithEmail(
      email: params.email,
      password: params.password,
      code: params.code,
      overage: params.overage,
      agree: params.agree,
      collect: params.collect,
      thirdparty: params.thirdparty,
      advertise: params.advertise,
    );
  }
}
