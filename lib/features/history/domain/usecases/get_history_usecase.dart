import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class GetHistoryUseCase {
  final HistoryRepository _repository;

  GetHistoryUseCase(this._repository);

  Future<Either<Failure, List<HistoryEntry>>> call({
    required String walletAddress,
    required String networks,
    bool? isNft,
    String? network,
    bool forceRefresh = false,
    OnHistoryRefreshed? onRefresh,
  }) async {
    final result = await _repository.getHistory(
      walletAddress: walletAddress,
      networks: networks,
      forceRefresh: forceRefresh,
      onRefresh: onRefresh != null
          ? (entries) => onRefresh(_applyFilter(entries, isNft, network))
          : null,
    );

    return result.map((entries) => _applyFilter(entries, isNft, network));
  }

  List<HistoryEntry> _applyFilter(
    List<HistoryEntry> entries,
    bool? isNft,
    String? network,
  ) {
    var result = entries;

    if (isNft != null) {
      result = result.where((e) => e.isNft == isNft).toList();
    }

    if (network != null) {
      result = result
          .where((e) => e.network.toLowerCase() == network.toLowerCase())
          .toList();
    }

    return result;
  }
}
