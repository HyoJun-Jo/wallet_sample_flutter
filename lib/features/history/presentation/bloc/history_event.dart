import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction_history.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class TokenHistoryRequested extends HistoryEvent {
  final String walletAddress;
  final String networks;
  final bool refreshFromNetwork;
  final String? filterNetwork;
  final String? contractAddress;

  const TokenHistoryRequested({
    required this.walletAddress,
    required this.networks,
    this.refreshFromNetwork = true,
    this.filterNetwork,
    this.contractAddress,
  });

  @override
  List<Object?> get props => [
        walletAddress,
        networks,
        refreshFromNetwork,
        filterNetwork,
        contractAddress,
      ];
}

class NftHistoryRequested extends HistoryEvent {
  final String walletAddress;
  final String networks;
  final bool refreshFromNetwork;
  final String? filterNetwork;
  final String? contractAddress;
  final String? tokenId;

  const NftHistoryRequested({
    required this.walletAddress,
    required this.networks,
    this.refreshFromNetwork = true,
    this.filterNetwork,
    this.contractAddress,
    this.tokenId,
  });

  @override
  List<Object?> get props => [
        walletAddress,
        networks,
        refreshFromNetwork,
        filterNetwork,
        contractAddress,
        tokenId,
      ];
}

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
