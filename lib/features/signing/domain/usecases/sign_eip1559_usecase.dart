import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sign_request.dart';
import '../repositories/signing_repository.dart';

/// Sign EIP-1559 Transaction UseCase
class SignEip1559UseCase implements UseCase<SignResult, SignEip1559Params> {
  final SigningRepository _repository;

  SignEip1559UseCase(this._repository);

  @override
  Future<Either<Failure, SignResult>> call(SignEip1559Params params) {
    return _repository.signEip1559(request: params.request);
  }
}

class SignEip1559Params extends Equatable {
  final Eip1559SignRequest request;

  const SignEip1559Params({required this.request});

  @override
  List<Object?> get props => [request];
}
