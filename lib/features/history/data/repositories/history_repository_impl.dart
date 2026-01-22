import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/transaction_history.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_datasource.dart';
import '../datasources/history_remote_datasource.dart';

/// History Repository implementation with cache-first pattern
class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _remoteDataSource;
  final HistoryLocalDataSource _localDataSource;

  HistoryRepositoryImpl({
    required HistoryRemoteDataSource remoteDataSource,
    required HistoryLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<TransactionHistory>>> getAllTransactions({
    required String walletAddress,
    required String networks,
    OnHistoryRefreshed? onRefresh,
    bool cacheOnly = false,
  }) async {
    try {
      // 1. Check cache first
      final cached = await _localDataSource.getCachedTransactions(walletAddress);
      if (cached != null && cached.isNotEmpty) {
        // If cacheOnly, just return cache without background refresh
        if (!cacheOnly) {
          _refreshInBackground(
            walletAddress: walletAddress,
            networks: networks,
            onRefresh: onRefresh,
          );
        }
        return Right(_sortByDate(cached));
      }

      // 2. No cache - if cacheOnly, return empty list
      if (cacheOnly) {
        return const Right([]);
      }

      // 3. Fetch from API
      final transactions = await _remoteDataSource.getTransactions(
        walletAddress: walletAddress,
        networks: networks,
      );

      // Save to cache
      await _localDataSource.cacheTransactions(walletAddress, transactions);

      return Right(_sortByDate(transactions));
    } catch (e) {
      // On error, try to return cache if available
      final cached = await _localDataSource.getCachedTransactions(walletAddress);
      if (cached != null && cached.isNotEmpty) {
        return Right(_sortByDate(cached));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionHistory>>> getTokenTransactions({
    required String walletAddress,
    required String networks,
    OnHistoryRefreshed? onRefresh,
    bool cacheOnly = false,
  }) async {
    // Get all transactions and filter: exclude NFT transfers
    final result = await getAllTransactions(
      walletAddress: walletAddress,
      networks: networks,
      onRefresh: onRefresh != null
          ? (txs) => onRefresh(_filterTokenTransactions(txs))
          : null,
      cacheOnly: cacheOnly,
    );

    return result.map(_filterTokenTransactions);
  }

  @override
  Future<Either<Failure, List<TransactionHistory>>> getNftTransactions({
    required String walletAddress,
    required String networks,
    OnHistoryRefreshed? onRefresh,
    bool cacheOnly = false,
  }) async {
    // Get all transactions and filter: only NFT transfers
    final result = await getAllTransactions(
      walletAddress: walletAddress,
      networks: networks,
      onRefresh: onRefresh != null
          ? (txs) => onRefresh(_filterNftTransactions(txs))
          : null,
      cacheOnly: cacheOnly,
    );

    return result.map(_filterNftTransactions);
  }

  /// Filter for token history: exclude NFT transfers
  List<TransactionHistory> _filterTokenTransactions(List<TransactionHistory> txs) {
    return txs.where((tx) => tx.type != TransactionType.nftTransfer).toList();
  }

  /// Filter for NFT history: only NFT transfers
  List<TransactionHistory> _filterNftTransactions(List<TransactionHistory> txs) {
    return txs.where((tx) => tx.type == TransactionType.nftTransfer).toList();
  }

  /// Sort transactions by date (newest first)
  List<TransactionHistory> _sortByDate(List<TransactionHistory> txs) {
    return txs..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Background refresh with callback
  Future<void> _refreshInBackground({
    required String walletAddress,
    required String networks,
    OnHistoryRefreshed? onRefresh,
  }) async {
    try {
      final transactions = await _remoteDataSource.getTransactions(
        walletAddress: walletAddress,
        networks: networks,
      );

      // Update cache
      await _localDataSource.cacheTransactions(walletAddress, transactions);

      // Notify caller with new data
      if (onRefresh != null) {
        onRefresh(_sortByDate(transactions));
      }
    } catch (_) {
      // Silent failure for background refresh
    }
  }
}
