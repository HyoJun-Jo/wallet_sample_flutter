import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/transaction_history.dart';
import '../repositories/history_repository.dart';

/// Use case for getting token transactions (excludes NFT)
class GetTokenTransactionsUseCase {
  final HistoryRepository _repository;

  GetTokenTransactionsUseCase(this._repository);

  Future<Either<Failure, List<TransactionHistory>>> call({
    required String walletAddress,
    required String networks,
    OnHistoryRefreshed? onRefresh,
    bool cacheOnly = false,
  }) {
    return _repository.getTokenTransactions(
      walletAddress: walletAddress,
      networks: networks,
      onRefresh: onRefresh,
      cacheOnly: cacheOnly,
    );
  }
}
