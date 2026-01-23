import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../transaction/domain/entities/transaction_entities.dart';
import '../../../transaction/domain/repositories/transaction_repository.dart';
import '../../domain/entities/sign_request.dart';
import '../../domain/usecases/sign_usecase.dart';
import '../../domain/usecases/sign_typed_data_usecase.dart';
import '../../domain/usecases/sign_hash_usecase.dart';
import 'signing_event.dart';
import 'signing_state.dart';

/// Signing BLoC
class SigningBloc extends Bloc<SigningEvent, SigningState> {
  final SignUseCase _signUseCase;
  final SignTypedDataUseCase _signTypedDataUseCase;
  final SignHashUseCase _signHashUseCase;
  final TransactionRepository _transactionRepository;

  SigningBloc({
    required SignUseCase signUseCase,
    required SignTypedDataUseCase signTypedDataUseCase,
    required SignHashUseCase signHashUseCase,
    required TransactionRepository transactionRepository,
  })  : _signUseCase = signUseCase,
        _signTypedDataUseCase = signTypedDataUseCase,
        _signHashUseCase = signHashUseCase,
        _transactionRepository = transactionRepository,
        super(const SigningInitial()) {
    on<SignMessageRequested>(_onSignMessageRequested);
    on<SignTypedDataRequested>(_onSignTypedDataRequested);
    on<SignHashRequested>(_onSignHashRequested);
    on<SignEip1559Requested>(_onSignEip1559Requested);
    on<SendTransactionRequested>(_onSendTransactionRequested);
    on<SigningCancelled>(_onCancelled);
  }

  Future<void> _onSignMessageRequested(
    SignMessageRequested event,
    Emitter<SigningState> emit,
  ) async {
    emit(const SigningLoading());

    final result = await _signUseCase(SignParams(
      request: SignRequest(
        msgType: event.msgType,
        accountId: event.accountId,
        network: event.network,
        msg: event.msg,
        language: event.language,
      ),
    ));

    result.fold(
      (failure) => emit(SigningError(message: failure.message)),
      (signResult) => emit(SigningCompleted(result: signResult)),
    );
  }

  Future<void> _onSignTypedDataRequested(
    SignTypedDataRequested event,
    Emitter<SigningState> emit,
  ) async {
    emit(const SigningLoading());

    final result = await _signTypedDataUseCase(SignTypedDataParams(
      request: TypedDataSignRequest(
        accountId: event.accountId,
        network: event.network,
        typeDataMsg: event.typeDataMsg,
      ),
    ));

    result.fold(
      (failure) => emit(SigningError(message: failure.message)),
      (signResult) => emit(SigningCompleted(result: signResult)),
    );
  }

  Future<void> _onSignHashRequested(
    SignHashRequested event,
    Emitter<SigningState> emit,
  ) async {
    emit(const SigningLoading());

    final result = await _signHashUseCase(SignHashParams(
      request: HashSignRequest(
        accountId: event.accountId,
        network: event.network,
        hash: event.hash,
      ),
    ));

    result.fold(
      (failure) => emit(SigningError(message: failure.message)),
      (signResult) => emit(SigningCompleted(result: signResult)),
    );
  }

  Future<void> _onSignEip1559Requested(
    SignEip1559Requested event,
    Emitter<SigningState> emit,
  ) async {
    emit(const SigningLoading());

    final result = await _transactionRepository.signTransaction(
      params: SignTransactionParams(
        network: event.network,
        from: event.from,
        to: event.to,
        value: event.value,
        data: event.data,
        nonce: event.nonce,
        gasLimit: event.gasLimit,
        maxPriorityFeePerGas: event.maxPriorityFeePerGas,
        maxFeePerGas: event.maxFeePerGas,
        type: SignType.eip1559,
      ),
    );

    result.fold(
      (failure) => emit(SigningError(message: failure.message)),
      (signedTx) => emit(TransactionSigned(
        signature: signedTx.signature,
        serializedTx: signedTx.serializedTx,
        rawTx: signedTx.rawTx,
      )),
    );
  }

  Future<void> _onSendTransactionRequested(
    SendTransactionRequested event,
    Emitter<SigningState> emit,
  ) async {
    emit(const SigningLoading());

    final result = await _transactionRepository.sendTransaction(
      params: SendTransactionParams(
        network: event.network,
        signedTx: event.signedTx,
      ),
    );

    result.fold(
      (failure) => emit(SigningError(message: failure.message)),
      (txResult) => emit(TransactionSent(txHash: txResult.txHash)),
    );
  }

  void _onCancelled(
    SigningCancelled event,
    Emitter<SigningState> emit,
  ) {
    emit(const SigningInitial());
  }
}
