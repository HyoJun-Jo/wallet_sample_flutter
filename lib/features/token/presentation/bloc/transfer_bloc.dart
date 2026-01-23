import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/usecases/send_token_usecase.dart';
import 'transfer_event.dart';
import 'transfer_state.dart';

/// Transfer BLoC
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final CreateTransferDataUseCase _createTransferDataUseCase;
  final SendTransactionUseCase _sendTransactionUseCase;

  TransferBloc({
    required CreateTransferDataUseCase createTransferDataUseCase,
    required SendTransactionUseCase sendTransactionUseCase,
  })  : _createTransferDataUseCase = createTransferDataUseCase,
        _sendTransactionUseCase = sendTransactionUseCase,
        super(const TransferInitial()) {
    on<TransferDataRequested>(_onDataRequested);
    on<SendTransactionRequested>(_onSendTransactionRequested);
    on<TransferCancelled>(_onCancelled);
  }

  Future<void> _onDataRequested(
    TransferDataRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(const TransferLoading());

    final result = await _createTransferDataUseCase(CreateTransferDataParams(
      request: TransferRequest(
        fromAddress: event.fromAddress,
        toAddress: event.toAddress,
        amount: event.amount,
        contractAddress: event.contractAddress,
        network: event.network,
      ),
    ));

    result.fold(
      (failure) => emit(TransferError(message: failure.message)),
      (transferData) => emit(TransferDataReady(transferData: transferData)),
    );
  }

  Future<void> _onSendTransactionRequested(
    SendTransactionRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(const TransferLoading());

    final result = await _sendTransactionUseCase(SendTransactionParams(
      network: event.network,
      rawData: event.rawData,
    ));

    result.fold(
      (failure) => emit(TransferError(message: failure.message)),
      (transferResult) => emit(TransferCompleted(result: transferResult)),
    );
  }

  void _onCancelled(
    TransferCancelled event,
    Emitter<TransferState> emit,
  ) {
    emit(const TransferInitial());
  }
}
