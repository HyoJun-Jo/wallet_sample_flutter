import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction_entities.dart';
import '../repositories/transaction_repository.dart';

class EstimateGasUseCase implements UseCase<EstimateGasResult, EstimateGasParams> {
  final TransactionRepository _repository;

  EstimateGasUseCase(this._repository);

  @override
  Future<Either<Failure, EstimateGasResult>> call(EstimateGasParams params) {
    return _repository.estimateGas(params: params);
  }
}
