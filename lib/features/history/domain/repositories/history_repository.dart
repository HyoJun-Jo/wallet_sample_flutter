import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/history_entry.dart';

typedef OnHistoryRefreshed = void Function(List<HistoryEntry> entries);

abstract class HistoryRepository {
  Future<Either<Failure, List<HistoryEntry>>> getHistory({
    required String walletAddress,
    required String networks,
    bool forceRefresh = false,
    OnHistoryRefreshed? onRefresh,
  });

  Future<void> clearCache(String walletAddress);
}
