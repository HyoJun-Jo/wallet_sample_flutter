import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/transaction_history.dart';

/// Callback for background refresh
typedef OnHistoryRefreshed = void Function(List<TransactionHistory> transactions);

/// History repository interface
abstract class HistoryRepository {
  /// Get all transactions (cache-first with background refresh)
  Future<Either<Failure, List<TransactionHistory>>> getAllTransactions({
    required String walletAddress,
    required String networks,
    OnHistoryRefreshed? onRefresh,
    bool cacheOnly = false,
  });

  /// Get token transactions (excludes NFT transfers)
  Future<Either<Failure, List<TransactionHistory>>> getTokenTransactions({
    required String walletAddress,
    required String networks,
    OnHistoryRefreshed? onRefresh,
    bool cacheOnly = false,
  });

  /// Get NFT transactions (only NFT transfers)
  Future<Either<Failure, List<TransactionHistory>>> getNftTransactions({
    required String walletAddress,
    required String networks,
    OnHistoryRefreshed? onRefresh,
    bool cacheOnly = false,
  });
}
