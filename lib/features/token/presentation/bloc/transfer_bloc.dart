import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/chain/chain_repository.dart';
import '../../../../shared/transaction/domain/entities/transaction_entities.dart';
import '../../../../shared/transaction/domain/repositories/transaction_repository.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/usecases/transfer_token_usecase.dart';
import '../../../token/data/models/transfer_model.dart';
import 'transfer_event.dart';
import 'transfer_state.dart';

/// Transfer BLoC (matches SDK - uses TransferTokenUseCase)
/// Supports two modes:
/// 1. PrepareTransfer → TransferDataReady (for showing confirmation UI)
/// 2. TransferRequested → TransferCompleted (full transfer flow)
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final TransferTokenUseCase _transferTokenUseCase;
  final TransactionRepository _transactionRepository;
  final ChainRepository _chainRepository;

  TransferBloc({
    required TransferTokenUseCase transferTokenUseCase,
    required TransactionRepository transactionRepository,
    required ChainRepository chainRepository,
  })  : _transferTokenUseCase = transferTokenUseCase,
        _transactionRepository = transactionRepository,
        _chainRepository = chainRepository,
        super(const TransferInitial()) {
    on<PrepareTransfer>(_onPrepareTransfer);
    on<TransferRequested>(_onTransferRequested);
    on<TransferReset>(_onReset);
  }

  /// Prepare transfer data (gas fees, etc.) for confirmation UI
  Future<void> _onPrepareTransfer(
    PrepareTransfer event,
    Emitter<TransferState> emit,
  ) async {
    emit(const TransferLoading());

    try {
      final chain = _chainRepository.getByNetwork(event.network);
      if (chain == null) {
        emit(TransferError(message: 'Unknown network: ${event.network}'));
        return;
      }

      final isNative = event.contractAddress.isEmpty;
      final decimals = isNative ? chain.decimals : 18; // ERC-20 typically 18

      // Calculate value in wei
      final value = _toWeiHex(event.amount, decimals);

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

      log('PrepareTransfer: gasLimit=$gasLimit, maxFeePerGas=$maxFeePerGas', name: 'TransferBloc');

      // Create TransferData for confirmation UI
      final transferData = TransferDataModel(
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

      // Create TransferParams for later execution
      final transferParams = TransferParams(
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

      emit(TransferDataReady(
        transferData: transferData,
        transferParams: transferParams,
      ));
    } catch (e) {
      log('PrepareTransfer error: $e', name: 'TransferBloc');
      emit(TransferError(message: e.toString()));
    }
  }

  /// Execute the full transfer flow (sign + send)
  Future<void> _onTransferRequested(
    TransferRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(const TransferLoading());

    final result = await _transferTokenUseCase(
      TransferTokenParams(transferParams: event.params),
    );

    result.fold(
      (failure) => emit(TransferError(message: failure.message)),
      (transferResult) => emit(TransferCompleted(result: transferResult)),
    );
  }

  void _onReset(
    TransferReset event,
    Emitter<TransferState> emit,
  ) {
    emit(const TransferInitial());
  }

  /// Convert amount string to wei (hex string)
  String _toWeiHex(String amount, int decimals) {
    final parts = amount.split('.');
    String intPart = parts[0];
    String decPart = parts.length > 1 ? parts[1] : '';

    // Pad or trim decimal part
    if (decPart.length < decimals) {
      decPart = decPart.padRight(decimals, '0');
    } else if (decPart.length > decimals) {
      decPart = decPart.substring(0, decimals);
    }

    // Combine and parse as BigInt
    final weiString = intPart + decPart;
    final wei = BigInt.parse(weiString);

    // Return as hex string
    return '0x${wei.toRadixString(16)}';
  }
}
