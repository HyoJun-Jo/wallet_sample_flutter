import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction_history.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class TokenHistoryLoaded extends HistoryState {
  final List<TransactionHistory> transactions;
  final String walletAddress;
  final bool isFromCache;

  const TokenHistoryLoaded({
    required this.transactions,
    required this.walletAddress,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [transactions, walletAddress, isFromCache];

  TokenHistoryLoaded copyWith({
    List<TransactionHistory>? transactions,
    String? walletAddress,
    bool? isFromCache,
  }) {
    return TokenHistoryLoaded(
      transactions: transactions ?? this.transactions,
      walletAddress: walletAddress ?? this.walletAddress,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

class NftHistoryLoaded extends HistoryState {
  final List<TransactionHistory> transactions;
  final String walletAddress;
  final bool isFromCache;

  const NftHistoryLoaded({
    required this.transactions,
    required this.walletAddress,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [transactions, walletAddress, isFromCache];

  NftHistoryLoaded copyWith({
    List<TransactionHistory>? transactions,
    String? walletAddress,
    bool? isFromCache,
  }) {
    return NftHistoryLoaded(
      transactions: transactions ?? this.transactions,
      walletAddress: walletAddress ?? this.walletAddress,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
