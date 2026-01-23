import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/signing_entities.dart';
import '../repositories/signing_repository.dart';

/// Sign Hash UseCase
class SignHashUseCase implements UseCase<SignResult, SignHashParams> {
  final SigningRepository _repository;

  SignHashUseCase(this._repository);

  @override
  Future<Either<Failure, SignResult>> call(SignHashParams params) {
    return _repository.signHash(params: params);
  }
}
