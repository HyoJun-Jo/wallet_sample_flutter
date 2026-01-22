import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sign_request.dart';
import '../repositories/signing_repository.dart';

/// Sign Hash UseCase
class SignHashUseCase implements UseCase<SignResult, SignHashParams> {
  final SigningRepository _repository;

  SignHashUseCase(this._repository);

  @override
  Future<Either<Failure, SignResult>> call(SignHashParams params) {
    return _repository.signHash(request: params.request);
  }
}

class SignHashParams extends Equatable {
  final HashSignRequest request;

  const SignHashParams({required this.request});

  @override
  List<Object?> get props => [request];
}
