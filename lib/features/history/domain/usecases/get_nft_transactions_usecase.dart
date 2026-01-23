import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/transaction_history.dart';
import '../repositories/history_repository.dart';

class GetNftTransactionsUseCase {
  final HistoryRepository _repository;

  GetNftTransactionsUseCase(this._repository);

  Future<Either<Failure, List<TransactionHistory>>> call({
    required String walletAddress,
    required String networks,
    String? filterNetwork,
    String? contractAddress,
    String? tokenId,
    bool cacheOnly = false,
    OnHistoryRefreshed? onRefresh,
  }) async {
    final result = await _repository.getNftTransactions(
      walletAddress: walletAddress,
      networks: networks,
      cacheOnly: cacheOnly,
      onRefresh: onRefresh != null
          ? (transactions) => onRefresh(_applyFilters(
                transactions,
                filterNetwork,
                contractAddress,
                tokenId,
              ))
          : null,
    );

    return result.map((transactions) => _applyFilters(
          transactions,
          filterNetwork,
          contractAddress,
          tokenId,
        ));
  }

  List<TransactionHistory> _applyFilters(
    List<TransactionHistory> transactions,
    String? filterNetwork,
    String? contractAddress,
    String? tokenId,
  ) {
    var filtered = transactions;

    if (filterNetwork != null) {
      filtered = filtered
          .where((tx) => tx.network.toLowerCase() == filterNetwork.toLowerCase())
          .toList();
    }

    if (contractAddress != null) {
      filtered = filtered
          .where((tx) =>
              tx.contractAddress?.toLowerCase() == contractAddress.toLowerCase())
          .toList();
    }

    if (tokenId != null) {
      filtered = filtered.where((tx) => tx.tokenId == tokenId).toList();
    }

    return filtered;
  }
}
