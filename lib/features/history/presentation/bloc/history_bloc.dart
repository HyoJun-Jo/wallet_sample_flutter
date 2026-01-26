import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_history_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetHistoryUseCase _getHistoryUseCase;

  HistoryBloc({
    required GetHistoryUseCase getHistoryUseCase,
  })  : _getHistoryUseCase = getHistoryUseCase,
        super(const HistoryInitial()) {
    on<HistoryRequested>(_onHistoryRequested);
    on<HistoryRefreshed>(_onHistoryRefreshed);
  }

  Future<void> _onHistoryRequested(
    HistoryRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());

    final result = await _getHistoryUseCase(
      walletAddress: event.walletAddress,
      networks: event.networks,
      isNft: event.isNft,
      network: event.network,
      forceRefresh: event.forceRefresh,
      onRefresh: (entries) {
        add(HistoryRefreshed(entries: entries));
      },
    );

    result.fold(
      (failure) => emit(HistoryError(message: failure.message)),
      (entries) => emit(HistoryLoaded(
        entries: entries,
        walletAddress: event.walletAddress,
      )),
    );
  }

  void _onHistoryRefreshed(
    HistoryRefreshed event,
    Emitter<HistoryState> emit,
  ) {
    final currentState = state;
    if (currentState is HistoryLoaded) {
      emit(currentState.copyWith(entries: event.entries));
    }
  }
}
