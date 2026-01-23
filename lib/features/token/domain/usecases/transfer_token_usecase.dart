import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../shared/signing/domain/entities/signing_entities.dart';
import '../../../../shared/signing/domain/repositories/signing_repository.dart';
import '../../../../shared/transaction/domain/entities/transaction_entities.dart';
import '../../../../shared/transaction/domain/repositories/transaction_repository.dart';
import '../entities/transfer.dart';
import '../repositories/token_repository.dart';

/// Transfer token UseCase (matches SDK TransferTokenUseCase)
/// Handles the entire token transfer flow:
/// 1. Get transfer data (ERC-20 ABI) if needed
/// 2. Get nonce
/// 3. Sign transaction
/// 4. Send transaction
class TransferTokenUseCase implements UseCase<TransferResult, TransferTokenParams> {
  final TokenRepository _tokenRepository;
  final TransactionRepository _transactionRepository;
  final SigningRepository _signingRepository;

  TransferTokenUseCase({
    required TokenRepository tokenRepository,
    required TransactionRepository transactionRepository,
    required SigningRepository signingRepository,
  })  : _tokenRepository = tokenRepository,
        _transactionRepository = transactionRepository,
        _signingRepository = signingRepository;

  @override
  Future<Either<Failure, TransferResult>> call(TransferTokenParams params) async {
    try {
      log('TransferTokenUseCase: Starting transfer', name: 'TransferTokenUseCase');
      log('  network: ${params.transferParams.network}', name: 'TransferTokenUseCase');
      log('  from: ${params.transferParams.fromAddress}', name: 'TransferTokenUseCase');
      log('  to: ${params.transferParams.toAddress}', name: 'TransferTokenUseCase');
      log('  amount: ${params.transferParams.amount}', name: 'TransferTokenUseCase');
      log('  isNative: ${params.transferParams.isNative}', name: 'TransferTokenUseCase');

      // Prepare transaction data
      String data = '0x';
      String to = params.transferParams.toAddress;
      String value = _toWeiHex(
        params.transferParams.amount,
        params.transferParams.decimals,
      );

      // 1. Get ERC-20 transfer data if not native token
      if (!params.transferParams.isNative) {
        log('TransferTokenUseCase: Getting ERC-20 transfer data', name: 'TransferTokenUseCase');

        final transferDataResult = await _tokenRepository.getTransferData(
          params: GetTransferDataParams(
            network: params.transferParams.network,
            to: params.transferParams.toAddress,
            value: value,
          ),
        );

        final transferData = transferDataResult.fold(
          (failure) {
            log('TransferTokenUseCase: Failed to get transfer data: ${failure.message}',
                name: 'TransferTokenUseCase');
            return null;
          },
          (result) => result,
        );

        if (transferData == null) {
          return Left(ServerFailure(message: 'Failed to get transfer data'));
        }

        data = transferData.data;
        to = params.transferParams.contractAddress!;
        value = '0x0'; // ERC-20 transfers send value = 0
        log('TransferTokenUseCase: ERC-20 data=$data', name: 'TransferTokenUseCase');
      }

      // 2. Get nonce
      log('TransferTokenUseCase: Getting nonce', name: 'TransferTokenUseCase');
      final nonceResult = await _transactionRepository.getNonce(
        address: params.transferParams.fromAddress,
        network: params.transferParams.network,
      );
      final nonce = nonceResult.fold(
        (failure) {
          log('TransferTokenUseCase: Failed to get nonce, using 0x0', name: 'TransferTokenUseCase');
          return '0x0';
        },
        (n) => n,
      );
      log('TransferTokenUseCase: nonce=$nonce', name: 'TransferTokenUseCase');

      // 3. Sign transaction
      log('TransferTokenUseCase: Signing transaction', name: 'TransferTokenUseCase');
      final signResult = await _signingRepository.signTransaction(
        params: SignTransactionParams(
          network: params.transferParams.network,
          from: params.transferParams.fromAddress,
          to: to,
          value: value,
          data: data,
          nonce: nonce,
          gasLimit: params.transferParams.gasLimit,
          maxFeePerGas: params.transferParams.gasFee.maxFeePerGas,
          maxPriorityFeePerGas: params.transferParams.gasFee.maxPriorityFeePerGas,
          type: SignType.eip1559,
        ),
      );

      final signedTx = signResult.fold(
        (failure) {
          log('TransferTokenUseCase: Signing failed: ${failure.message}', name: 'TransferTokenUseCase');
          return null;
        },
        (result) => result.serializedTx.isNotEmpty ? result.serializedTx : result.rawTx,
      );

      if (signedTx == null || signedTx.isEmpty) {
        return Left(ServerFailure(message: 'Signing failed'));
      }
      log('TransferTokenUseCase: signedTx=${signedTx.substring(0, 20)}...', name: 'TransferTokenUseCase');

      // 4. Send transaction
      log('TransferTokenUseCase: Sending transaction', name: 'TransferTokenUseCase');
      final sendResult = await _transactionRepository.sendTransaction(
        params: SendTransactionParams(
          network: params.transferParams.network,
          signedSerializeTx: signedTx,
        ),
      );

      return sendResult.fold(
        (failure) {
          log('TransferTokenUseCase: Send failed: ${failure.message}', name: 'TransferTokenUseCase');
          return Left(failure);
        },
        (result) {
          log('TransferTokenUseCase: Success! txHash=${result.transactionHash}',
              name: 'TransferTokenUseCase');
          return Right(TransferResult(transactionHash: result.transactionHash));
        },
      );
    } catch (e) {
      log('TransferTokenUseCase: Exception: $e', name: 'TransferTokenUseCase');
      return Left(ServerFailure(message: e.toString()));
    }
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

/// Parameters for TransferTokenUseCase
class TransferTokenParams extends Equatable {
  final TransferParams transferParams;

  const TransferTokenParams({required this.transferParams});

  @override
  List<Object?> get props => [transferParams];
}
