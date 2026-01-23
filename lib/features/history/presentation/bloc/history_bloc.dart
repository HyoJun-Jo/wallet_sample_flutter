import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_nft_transactions_usecase.dart';
import '../../domain/usecases/get_token_transactions_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

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

    if (event.refreshFromNetwork) {
      // Cache-first with background refresh
      final result = await _getTokenTransactionsUseCase(
        walletAddress: event.walletAddress,
        networks: event.networks,
        filterNetwork: event.filterNetwork,
        contractAddress: event.contractAddress,
        cacheOnly: false,
        onRefresh: (transactions) {
          add(HistoryRefreshed(transactions: transactions, isTokenHistory: true));
        },
      );

      result.fold(
        (failure) => emit(HistoryError(message: failure.message)),
        (transactions) => emit(TokenHistoryLoaded(
          transactions: transactions,
          walletAddress: event.walletAddress,
          isFromCache: true,
        )),
      );
    } else {
      // Cache only
      final result = await _getTokenTransactionsUseCase(
        walletAddress: event.walletAddress,
        networks: event.networks,
        filterNetwork: event.filterNetwork,
        contractAddress: event.contractAddress,
        cacheOnly: true,
      );

      result.fold(
        (failure) => emit(HistoryError(message: failure.message)),
        (transactions) {
          if (transactions.isEmpty) {
            // No cache, fetch from network
            add(TokenHistoryRequested(
              walletAddress: event.walletAddress,
              networks: event.networks,
              refreshFromNetwork: true,
              filterNetwork: event.filterNetwork,
              contractAddress: event.contractAddress,
            ));
          } else {
            emit(TokenHistoryLoaded(
              transactions: transactions,
              walletAddress: event.walletAddress,
              isFromCache: false,
            ));
          }
        },
      );
    }
  }

  Future<void> _onNftHistoryRequested(
    NftHistoryRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());

    if (event.refreshFromNetwork) {
      final result = await _getNftTransactionsUseCase(
        walletAddress: event.walletAddress,
        networks: event.networks,
        filterNetwork: event.filterNetwork,
        contractAddress: event.contractAddress,
        tokenId: event.tokenId,
        cacheOnly: false,
        onRefresh: (transactions) {
          add(HistoryRefreshed(transactions: transactions, isTokenHistory: false));
        },
      );

      result.fold(
        (failure) => emit(HistoryError(message: failure.message)),
        (transactions) => emit(NftHistoryLoaded(
          transactions: transactions,
          walletAddress: event.walletAddress,
          isFromCache: true,
        )),
      );
    } else {
      final result = await _getNftTransactionsUseCase(
        walletAddress: event.walletAddress,
        networks: event.networks,
        filterNetwork: event.filterNetwork,
        contractAddress: event.contractAddress,
        tokenId: event.tokenId,
        cacheOnly: true,
      );

      result.fold(
        (failure) => emit(HistoryError(message: failure.message)),
        (transactions) {
          if (transactions.isEmpty) {
            add(NftHistoryRequested(
              walletAddress: event.walletAddress,
              networks: event.networks,
              refreshFromNetwork: true,
              filterNetwork: event.filterNetwork,
              contractAddress: event.contractAddress,
              tokenId: event.tokenId,
            ));
          } else {
            emit(NftHistoryLoaded(
              transactions: transactions,
              walletAddress: event.walletAddress,
              isFromCache: false,
            ));
          }
        },
      );
    }
  }

  void _onHistoryRefreshed(
    HistoryRefreshed event,
    Emitter<HistoryState> emit,
  ) {
    final currentState = state;

    if (event.isTokenHistory && currentState is TokenHistoryLoaded) {
      emit(currentState.copyWith(
        transactions: event.transactions,
        isFromCache: false,
      ));
    } else if (!event.isTokenHistory && currentState is NftHistoryLoaded) {
      emit(currentState.copyWith(
        transactions: event.transactions,
        isFromCache: false,
      ));
    }
  }
}
