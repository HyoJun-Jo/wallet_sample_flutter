import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sign_request.dart';
import '../repositories/signing_repository.dart';

/// Sign UseCase
class SignUseCase implements UseCase<SignResult, SignParams> {
  final SigningRepository _repository;

  SignUseCase(this._repository);

  @override
  Future<Either<Failure, SignResult>> call(SignParams params) {
    return _repository.sign(request: params.request);
  }
}

class SignParams extends Equatable {
  final SignRequest request;

  const SignParams({required this.request});

  @override
  List<Object?> get props => [request];
}
