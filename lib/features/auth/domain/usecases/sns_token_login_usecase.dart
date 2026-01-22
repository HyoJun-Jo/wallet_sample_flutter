import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

/// SNS token login use case
class SnsTokenLoginUseCase
    implements UseCase<SnsLoginResult, SnsTokenLoginParams> {
  final AuthRepository _repository;

  SnsTokenLoginUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, SnsLoginResult>> call(
      SnsTokenLoginParams params) async {
    return await _repository.loginWithSnsToken(
      snsToken: params.snsToken,
      snsType: params.loginType.name,
    );
  }
}

/// SNS token login parameters
class SnsTokenLoginParams extends Equatable {
  final String snsToken;
  final LoginType loginType;

  const SnsTokenLoginParams({
    required this.snsToken,
    required this.loginType,
  });

  @override
  List<Object?> get props => [snsToken, loginType];
}
