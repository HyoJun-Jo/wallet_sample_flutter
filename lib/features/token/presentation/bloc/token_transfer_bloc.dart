import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/chain/chain_repository.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../shared/transaction/domain/entities/transaction_entities.dart';
import '../../../../shared/transaction/domain/repositories/transaction_repository.dart';
import '../../domain/entities/token_transfer.dart';
import '../../domain/usecases/token_transfer_usecase.dart';
import 'token_transfer_event.dart';
import 'token_transfer_state.dart';

/// Token Transfer BLoC (matches SDK - uses TokenTransferUseCase)
/// Supports two modes:
/// 1. PrepareTokenTransfer → TokenTransferDataReady (for showing confirmation UI)
/// 2. TokenTransferRequested → TokenTransferCompleted (full transfer flow)
class TokenTransferBloc extends Bloc<TokenTransferEvent, TokenTransferState> {
  final TokenTransferUseCase _tokenTransferUseCase;
  final TransactionRepository _transactionRepository;
  final ChainRepository _chainRepository;

  TokenTransferBloc({
    required TokenTransferUseCase tokenTransferUseCase,
    required TransactionRepository transactionRepository,
    required ChainRepository chainRepository,
  })  : _tokenTransferUseCase = tokenTransferUseCase,
        _transactionRepository = transactionRepository,
        _chainRepository = chainRepository,
        super(const TokenTransferInitial()) {
    on<PrepareTokenTransfer>(_onPrepareTransfer);
    on<TokenTransferRequested>(_onTransferRequested);
    on<TokenTransferReset>(_onReset);
  }

  /// Prepare transfer data (gas fees, etc.) for confirmation UI
  Future<void> _onPrepareTransfer(
    PrepareTokenTransfer event,
    Emitter<TokenTransferState> emit,
  ) async {
    emit(const TokenTransferLoading());

    try {
      final chain = _chainRepository.getByNetwork(event.network);
      if (chain == null) {
        emit(TokenTransferError(message: 'Unknown network: ${event.network}'));
        return;
      }

      final isNative = event.contractAddress.isEmpty;
      final decimals = isNative ? chain.decimals : 18; // ERC-20 typically 18

      // Calculate value in wei
      final value = FormatUtils.toWeiHex(event.amount, decimals);

      // Determine to address and data
      final String toAddress;
      final String txValue;
      final String data;

      if (isNative) {
        toAddress = event.toAddress;
        txValue = value;
        data = '0x';
      } else {
        // ERC-20: to = contract, value = 0, data will be set later
        toAddress = event.contractAddress;
        txValue = '0x0';
        data = '0x'; // Will be calculated when executing
      }

      // Get gas fees, nonce, and estimate gas in parallel
      final results = await Future.wait([
        _transactionRepository.getGasFees(network: event.network),
        _transactionRepository.getNonce(address: event.fromAddress, network: event.network),
        _transactionRepository.estimateGas(
          params: EstimateGasParams(
            network: event.network,
            from: event.fromAddress,
            to: toAddress,
            value: txValue,
            data: data,
          ),
        ),
      ]);

      final gasFeesResult = results[0] as dynamic;
      final nonceResult = results[1] as dynamic;
      final gasLimitResult = results[2] as dynamic;

      // Extract results with fallbacks
      final gasFees = gasFeesResult.fold(
        (failure) => null,
        (fees) => fees as GasFees,
      );
      final nonce = nonceResult.fold(
        (failure) => '0x0',
        (n) => n as String,
      );
      final gasLimit = gasLimitResult.fold(
        (failure) => data == '0x' ? '0x5208' : '0x15f90', // 21000 for native, 90000 for ERC-20
        (result) => (result as EstimateGasResult).gasLimit,
      );

      // Use medium gas fee by default
      final maxFeePerGas = gasFees?.medium.maxFeePerGas ?? '0x6fc23ac00'; // ~30 gwei
      final maxPriorityFeePerGas = gasFees?.medium.maxPriorityFeePerGas ?? '0x59682f00'; // ~1.5 gwei

      log('PrepareTokenTransfer: gasLimit=$gasLimit, maxFeePerGas=$maxFeePerGas', name: 'TokenTransferBloc');

      final transferData = TokenTransferData(
        to: toAddress,
        from: event.fromAddress,
        data: data,
        value: txValue,
        gasLimit: gasLimit,
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        nonce: nonce,
        network: event.network,
      );

      // Create TokenTransferParams for later execution
      final transferParams = TokenTransferParams(
        fromAddress: event.fromAddress,
        toAddress: event.toAddress,
        contractAddress: event.contractAddress.isNotEmpty ? event.contractAddress : null,
        amount: event.amount,
        decimals: decimals,
        network: event.network,
        gasFee: GasFeeDetail(
          maxFeePerGas: maxFeePerGas,
          maxPriorityFeePerGas: maxPriorityFeePerGas,
        ),
        gasLimit: gasLimit,
      );

      emit(TokenTransferDataReady(
        transferData: transferData,
        transferParams: transferParams,
      ));
    } catch (e) {
      log('PrepareTokenTransfer error: $e', name: 'TokenTransferBloc');
      emit(TokenTransferError(message: e.toString()));
    }
  }

  /// Execute the full transfer flow (sign + send)
  Future<void> _onTransferRequested(
    TokenTransferRequested event,
    Emitter<TokenTransferState> emit,
  ) async {
    emit(const TokenTransferLoading());

    final result = await _tokenTransferUseCase(
      TokenTransferUseCaseParams(transferParams: event.params),
    );

    result.fold(
      (failure) => emit(TokenTransferError(message: failure.message)),
      (transferResult) => emit(TokenTransferCompleted(result: transferResult)),
    );
  }

  void _onReset(
    TokenTransferReset event,
    Emitter<TokenTransferState> emit,
  ) {
    emit(const TokenTransferInitial());
  }
}
