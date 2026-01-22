import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Verify code parameters
class VerifyCodeParams extends Equatable {
  final String email;
  final String code;

  const VerifyCodeParams({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

/// Verify code use case
class VerifyCodeUseCase implements UseCase<void, VerifyCodeParams> {
  final AuthRepository _repository;

  VerifyCodeUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, void>> call(VerifyCodeParams params) async {
    return await _repository.verifyCode(
      email: params.email,
      code: params.code,
    );
  }
}
