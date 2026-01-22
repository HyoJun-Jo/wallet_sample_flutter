import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction_history.dart';

/// History events
abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Request token history (excludes NFT)
class TokenHistoryRequested extends HistoryEvent {
  final String walletAddress;
  final String networks;
  /// Filter by specific network (e.g., 'ethereum', 'polygon')
  final String? filterNetwork;
  /// Filter by specific token contract address (null for native coin)
  final String? contractAddress;
  /// Filter by native coin only (true = only coin_transfer)
  final bool? isNativeCoin;

  const TokenHistoryRequested({
    required this.walletAddress,
    required this.networks,
    this.filterNetwork,
    this.contractAddress,
    this.isNativeCoin,
  });

  @override
  List<Object?> get props => [walletAddress, networks, filterNetwork, contractAddress, isNativeCoin];
}

/// Request NFT history
class NftHistoryRequested extends HistoryEvent {
  final String walletAddress;
  final String networks;
  /// Filter by specific network
  final String? filterNetwork;
  /// Filter by NFT contract address
  final String? contractAddress;
  /// Filter by NFT token ID
  final String? tokenId;

  const NftHistoryRequested({
    required this.walletAddress,
    required this.networks,
    this.filterNetwork,
    this.contractAddress,
    this.tokenId,
  });

  @override
  List<Object?> get props => [walletAddress, networks, filterNetwork, contractAddress, tokenId];
}

/// History refreshed from background
class HistoryRefreshed extends HistoryEvent {
  final List<TransactionHistory> transactions;
  final bool isTokenHistory;

  const HistoryRefreshed({
    required this.transactions,
    required this.isTokenHistory,
  });

  @override
  List<Object?> get props => [transactions, isTokenHistory];
}
