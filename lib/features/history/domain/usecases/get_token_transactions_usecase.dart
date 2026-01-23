import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/transaction_history.dart';
import '../repositories/history_repository.dart';

class GetTokenTransactionsUseCase {
  final HistoryRepository _repository;

  GetTokenTransactionsUseCase(this._repository);

  Future<Either<Failure, List<TransactionHistory>>> call({
    required String walletAddress,
    required String networks,
    String? filterNetwork,
    String? contractAddress,
    bool cacheOnly = false,
    OnHistoryRefreshed? onRefresh,
  }) async {
    final result = await _repository.getTokenTransactions(
      walletAddress: walletAddress,
      networks: networks,
      cacheOnly: cacheOnly,
      onRefresh: onRefresh != null
          ? (transactions) => onRefresh(_applyFilters(
                transactions,
                filterNetwork,
                contractAddress,
              ))
          : null,
    );

    return result.map((transactions) => _applyFilters(
          transactions,
          filterNetwork,
          contractAddress,
        ));
  }

  List<TransactionHistory> _applyFilters(
    List<TransactionHistory> transactions,
    String? filterNetwork,
    String? contractAddress,
  ) {
    var filtered = transactions;

    if (filterNetwork != null) {
      filtered = filtered
          .where((tx) => tx.network.toLowerCase() == filterNetwork.toLowerCase())
          .toList();
    }

    if (contractAddress != null) {
      if (contractAddress.isEmpty) {
        filtered = filtered.where((tx) => tx.contractAddress == null).toList();
      } else {
        filtered = filtered
            .where((tx) =>
                tx.contractAddress?.toLowerCase() == contractAddress.toLowerCase())
            .toList();
      }
    }

    return filtered;
  }
}
