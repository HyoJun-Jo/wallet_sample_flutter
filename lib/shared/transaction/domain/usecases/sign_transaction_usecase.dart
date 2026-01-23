import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction_entities.dart';
import '../repositories/transaction_repository.dart';

class SignTransactionUseCase implements UseCase<SignedTransaction, SignTransactionParams> {
  final TransactionRepository _repository;

  SignTransactionUseCase(this._repository);

  @override
  Future<Either<Failure, SignedTransaction>> call(SignTransactionParams params) {
    return _repository.signTransaction(params: params);
  }
}
