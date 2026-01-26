import 'package:equatable/equatable.dart';

import '../../domain/entities/history_entry.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryRequested extends HistoryEvent {
  final String walletAddress;
  final String networks;
  final bool? isNft;
  final String? network;
  final bool forceRefresh;

  const HistoryRequested({
    required this.walletAddress,
    required this.networks,
    this.isNft,
    this.network,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [walletAddress, networks, isNft, network, forceRefresh];
}

class HistoryRefreshed extends HistoryEvent {
  final List<HistoryEntry> entries;

  const HistoryRefreshed({required this.entries});

  @override
  List<Object?> get props => [entries];
}
