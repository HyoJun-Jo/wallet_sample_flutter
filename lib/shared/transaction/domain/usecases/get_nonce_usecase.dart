import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/transaction_repository.dart';

class GetNonceParams {
  final String address;
  final String network;

  const GetNonceParams({
    required this.address,
    required this.network,
  });
}

class GetNonceUseCase implements UseCase<String, GetNonceParams> {
  final TransactionRepository _repository;

  GetNonceUseCase(this._repository);

  @override
  Future<Either<Failure, String>> call(GetNonceParams params) {
    return _repository.getNonce(
      address: params.address,
      network: params.network,
    );
  }
}
