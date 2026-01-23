import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/signing_entities.dart';
import '../repositories/signing_repository.dart';

/// Sign Typed Data UseCase
class SignTypedDataUseCase implements UseCase<SignTypedDataResult, SignTypedDataParams> {
  final SigningRepository _repository;

  SignTypedDataUseCase(this._repository);

  @override
  Future<Either<Failure, SignTypedDataResult>> call(SignTypedDataParams params) {
    return _repository.signTypedData(params: params);
  }
}
