import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/transaction_history.dart';
import '../repositories/history_repository.dart';

/// Use case for getting NFT transactions
class GetNftTransactionsUseCase {
  final HistoryRepository _repository;

  GetNftTransactionsUseCase(this._repository);

  Future<Either<Failure, List<TransactionHistory>>> call({
    required String walletAddress,
    required String networks,
    OnHistoryRefreshed? onRefresh,
    bool cacheOnly = false,
  }) {
    return _repository.getNftTransactions(
      walletAddress: walletAddress,
      networks: networks,
      onRefresh: onRefresh,
      cacheOnly: cacheOnly,
    );
  }
}
