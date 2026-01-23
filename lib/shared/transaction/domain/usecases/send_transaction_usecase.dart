import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction_entities.dart';
import '../repositories/transaction_repository.dart';

class SendTransactionUseCase implements UseCase<TransactionResult, SendTransactionParams> {
  final TransactionRepository _repository;

  SendTransactionUseCase(this._repository);

  @override
  Future<Either<Failure, TransactionResult>> call(SendTransactionParams params) {
    return _repository.sendTransaction(params: params);
  }
}
