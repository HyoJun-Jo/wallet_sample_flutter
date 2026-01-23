import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/signing_entities.dart';
import '../repositories/signing_repository.dart';

/// Personal Sign UseCase
class PersonalSignUseCase implements UseCase<SignResult, PersonalSignParams> {
  final SigningRepository _repository;

  PersonalSignUseCase(this._repository);

  @override
  Future<Either<Failure, SignResult>> call(PersonalSignParams params) {
    return _repository.personalSign(params: params);
  }
}
