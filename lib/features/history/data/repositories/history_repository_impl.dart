import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_datasource.dart';
import '../datasources/history_remote_datasource.dart';

/// Default epoch since days for history query (30 days)
const int kEpochSinceDays = 30;

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _remoteDataSource;
  final HistoryLocalDataSource _localDataSource;

  HistoryRepositoryImpl({
    required HistoryRemoteDataSource remoteDataSource,
    required HistoryLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<HistoryEntry>>> getHistory({
    required String walletAddress,
    required String networks,
    bool forceRefresh = false,
    OnHistoryRefreshed? onRefresh,
  }) async {
    try {
      final cached = await _localDataSource.getCachedHistory(walletAddress);
      if (cached != null && cached.isNotEmpty) {
        final entities = cached.map((m) => m.toEntity()).toList();

        if (forceRefresh) {
          _refreshInBackground(
            walletAddress: walletAddress,
            networks: networks,
            onRefresh: onRefresh,
          );
        }

        return Right(_sortByDate(entities));
      }

      final models = await _remoteDataSource.getHistory(
        walletAddress: walletAddress,
        networks: networks,
        epochSince: _getEpochSince(),
      );

      await _localDataSource.cacheHistory(walletAddress, models);

      final entities = models.map((m) => m.toEntity()).toList();
      return Right(_sortByDate(entities));
    } catch (e) {
      final cached = await _localDataSource.getCachedHistory(walletAddress);
      if (cached != null && cached.isNotEmpty) {
        final entities = cached.map((m) => m.toEntity()).toList();
        return Right(_sortByDate(entities));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<void> clearCache(String walletAddress) async {
    await _localDataSource.clearCachedHistory(walletAddress);
  }

  List<HistoryEntry> _sortByDate(List<HistoryEntry> entries) {
    return entries..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Calculate epoch since timestamp (30 days ago in seconds)
  int _getEpochSince() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now - (kEpochSinceDays * 24 * 60 * 60);
  }

  Future<void> _refreshInBackground({
    required String walletAddress,
    required String networks,
    OnHistoryRefreshed? onRefresh,
  }) async {
    try {
      final models = await _remoteDataSource.getHistory(
        walletAddress: walletAddress,
        networks: networks,
        epochSince: _getEpochSince(),
      );

      await _localDataSource.cacheHistory(walletAddress, models);

      if (onRefresh != null) {
        final entities = models.map((m) => m.toEntity()).toList();
        onRefresh(_sortByDate(entities));
      }
    } catch (_) {
      // Silent failure for background refresh
    }
  }
}
