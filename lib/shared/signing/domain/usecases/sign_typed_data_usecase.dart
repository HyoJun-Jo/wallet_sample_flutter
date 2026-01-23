import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sign_request.dart';
import '../repositories/signing_repository.dart';

/// Sign Typed Data UseCase
class SignTypedDataUseCase implements UseCase<SignResult, SignTypedDataParams> {
  final SigningRepository _repository;

  SignTypedDataUseCase(this._repository);

  @override
  Future<Either<Failure, SignResult>> call(SignTypedDataParams params) {
    return _repository.signTypedData(request: params.request);
  }
}

class SignTypedDataParams extends Equatable {
  final TypedDataSignRequest request;

  const SignTypedDataParams({required this.request});

  @override
  List<Object?> get props => [request];
}
