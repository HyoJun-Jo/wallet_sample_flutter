import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/transaction_history.dart';
import '../../domain/usecases/get_nft_transactions_usecase.dart';
import '../../domain/usecases/get_token_transactions_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

/// History BLoC
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetTokenTransactionsUseCase _getTokenTransactionsUseCase;
  final GetNftTransactionsUseCase _getNftTransactionsUseCase;

  HistoryBloc({
    required GetTokenTransactionsUseCase getTokenTransactionsUseCase,
    required GetNftTransactionsUseCase getNftTransactionsUseCase,
  })  : _getTokenTransactionsUseCase = getTokenTransactionsUseCase,
        _getNftTransactionsUseCase = getNftTransactionsUseCase,
        super(const HistoryInitial()) {
    on<TokenHistoryRequested>(_onTokenHistoryRequested);
    on<NftHistoryRequested>(_onNftHistoryRequested);
    on<HistoryRefreshed>(_onHistoryRefreshed);
  }

  Future<void> _onTokenHistoryRequested(
    TokenHistoryRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());

    // If filtering by specific token (from detail page), use cache only
    final cacheOnly = event.filterNetwork != null;

    final result = await _getTokenTransactionsUseCase(
      walletAddress: event.walletAddress,
      networks: event.networks,
      cacheOnly: cacheOnly,
      onRefresh: cacheOnly
          ? null
          : (transactions) {
              final filtered = _filterTransactions(
                transactions,
                event.filterNetwork,
                event.contractAddress,
                event.isNativeCoin,
              );
              add(HistoryRefreshed(transactions: filtered, isTokenHistory: true));
            },
    );

    result.fold(
      (failure) => emit(HistoryError(message: failure.message)),
      (transactions) {
        final filtered = _filterTransactions(
          transactions,
          event.filterNetwork,
          event.contractAddress,
          event.isNativeCoin,
        );
        emit(TokenHistoryLoaded(
          transactions: filtered,
          walletAddress: event.walletAddress,
          isFromCache: !cacheOnly, // Only show updating indicator if not cache-only
        ));
      },
    );
  }

  /// Filter transactions by network, contract address, or native coin type
  List<TransactionHistory> _filterTransactions(
    List<TransactionHistory> transactions,
    String? filterNetwork,
    String? contractAddress,
    bool? isNativeCoin,
  ) {
    var filtered = transactions;

    // Step 1: Filter by network first
    if (filterNetwork != null) {
      filtered = filtered
          .where((tx) => tx.network.toLowerCase() == filterNetwork.toLowerCase())
          .toList();
    }

    // Step 2: Additional filtering by token type
    // No additional filter needed
    if (contractAddress == null && isNativeCoin == null) {
      return filtered;
    }

    // Native coin filter: only coin_transfer type
    if (isNativeCoin == true) {
      return filtered
          .where((tx) => tx.type == TransactionType.coinTransfer)
          .toList();
    }

    // Contract address filter: match contractAddress
    if (contractAddress != null) {
      return filtered
          .where((tx) =>
              tx.contractAddress?.toLowerCase() == contractAddress.toLowerCase())
          .toList();
    }

    return filtered;
  }

  Future<void> _onNftHistoryRequested(
    NftHistoryRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());

    // If filtering by specific NFT (from detail page), use cache only
    final cacheOnly = event.filterNetwork != null;

    final result = await _getNftTransactionsUseCase(
      walletAddress: event.walletAddress,
      networks: event.networks,
      cacheOnly: cacheOnly,
      onRefresh: cacheOnly
          ? null
          : (transactions) {
              final filtered = _filterNftTransactions(
                transactions,
                event.filterNetwork,
                event.contractAddress,
                event.tokenId,
              );
              add(HistoryRefreshed(transactions: filtered, isTokenHistory: false));
            },
    );

    result.fold(
      (failure) => emit(HistoryError(message: failure.message)),
      (transactions) {
        final filtered = _filterNftTransactions(
          transactions,
          event.filterNetwork,
          event.contractAddress,
          event.tokenId,
        );
        emit(NftHistoryLoaded(
          transactions: filtered,
          walletAddress: event.walletAddress,
          isFromCache: !cacheOnly,
        ));
      },
    );
  }

  /// Filter NFT transactions by network, contract address, and token ID
  List<TransactionHistory> _filterNftTransactions(
    List<TransactionHistory> transactions,
    String? filterNetwork,
    String? contractAddress,
    String? tokenId,
  ) {
    var filtered = transactions;

    // Step 1: Filter by network
    if (filterNetwork != null) {
      filtered = filtered
          .where((tx) => tx.network.toLowerCase() == filterNetwork.toLowerCase())
          .toList();
    }

    // Step 2: Filter by contract address
    if (contractAddress != null) {
      filtered = filtered
          .where((tx) =>
              tx.contractAddress?.toLowerCase() == contractAddress.toLowerCase())
          .toList();
    }

    // Step 3: Filter by token ID
    if (tokenId != null) {
      filtered = filtered
          .where((tx) => tx.tokenId == tokenId)
          .toList();
    }

    return filtered;
  }

  void _onHistoryRefreshed(
    HistoryRefreshed event,
    Emitter<HistoryState> emit,
  ) {
    if (event.isTokenHistory) {
      final currentState = state;
      if (currentState is TokenHistoryLoaded) {
        emit(currentState.copyWith(
          transactions: event.transactions,
          isFromCache: false,
        ));
      }
    } else {
      final currentState = state;
      if (currentState is NftHistoryLoaded) {
        emit(currentState.copyWith(
          transactions: event.transactions,
          isFromCache: false,
        ));
      }
    }
  }
}
