import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction_entities.dart';
import '../repositories/transaction_repository.dart';

class GetGasFeesParams {
  final String network;

  const GetGasFeesParams({required this.network});
}

class GetGasFeesUseCase implements UseCase<GasFees, GetGasFeesParams> {
  final TransactionRepository _repository;

  GetGasFeesUseCase(this._repository);

  @override
  Future<Either<Failure, GasFees>> call(GetGasFeesParams params) {
    return _repository.getGasFees(network: params.network);
  }
}
