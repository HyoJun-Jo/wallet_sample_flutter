import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../shared/signing/domain/entities/signing_entities.dart';
import '../../../../shared/signing/domain/repositories/signing_repository.dart';
import '../../../../shared/transaction/domain/entities/transaction_entities.dart';
import '../../../../shared/transaction/domain/repositories/transaction_repository.dart';
import '../entities/token_transfer.dart';
import '../repositories/token_repository.dart';

/// Transfer token UseCase (matches SDK TransferTokenUseCase)
/// Handles the entire token transfer flow:
/// 1. Get transfer data (ERC-20 ABI) if needed
/// 2. Get nonce
/// 3. Sign transaction
/// 4. Send transaction
class TokenTransferUseCase implements UseCase<TokenTransferResult, TokenTransferUseCaseParams> {
  final TokenRepository _tokenRepository;
  final TransactionRepository _transactionRepository;
  final SigningRepository _signingRepository;

  TokenTransferUseCase({
    required TokenRepository tokenRepository,
    required TransactionRepository transactionRepository,
    required SigningRepository signingRepository,
  })  : _tokenRepository = tokenRepository,
        _transactionRepository = transactionRepository,
        _signingRepository = signingRepository;

  @override
  Future<Either<Failure, TokenTransferResult>> call(TokenTransferUseCaseParams params) async {
    try {
      log('TokenTransferUseCase: Starting transfer', name: 'TokenTransferUseCase');
      log('  network: ${params.transferParams.network}', name: 'TokenTransferUseCase');
      log('  from: ${params.transferParams.fromAddress}', name: 'TokenTransferUseCase');
      log('  to: ${params.transferParams.toAddress}', name: 'TokenTransferUseCase');
      log('  amount: ${params.transferParams.amount}', name: 'TokenTransferUseCase');
      log('  isNative: ${params.transferParams.isNative}', name: 'TokenTransferUseCase');

      // Prepare transaction data
      String data = '0x';
      String to = params.transferParams.toAddress;
      String value = FormatUtils.toWeiHex(
        params.transferParams.amount,
        params.transferParams.decimals,
      );

      // 1. Get ERC-20 transfer data if not native token
      if (!params.transferParams.isNative) {
        log('TokenTransferUseCase: Getting ERC-20 transfer data', name: 'TokenTransferUseCase');

        final transferDataResult = await _tokenRepository.getTransferData(
          params: GetTokenTransferDataParams(
            network: params.transferParams.network,
            to: params.transferParams.toAddress,
            value: value,
          ),
        );

        final transferData = transferDataResult.fold(
          (failure) {
            log('TokenTransferUseCase: Failed to get transfer data: ${failure.message}',
                name: 'TokenTransferUseCase');
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
        log('TokenTransferUseCase: ERC-20 data=$data', name: 'TokenTransferUseCase');
      }

      // 2. Get nonce
      log('TokenTransferUseCase: Getting nonce', name: 'TokenTransferUseCase');
      final nonceResult = await _transactionRepository.getNonce(
        address: params.transferParams.fromAddress,
        network: params.transferParams.network,
      );
      final nonce = nonceResult.fold(
        (failure) {
          log('TokenTransferUseCase: Failed to get nonce, using 0x0', name: 'TokenTransferUseCase');
          return '0x0';
        },
        (n) => n,
      );
      log('TokenTransferUseCase: nonce=$nonce', name: 'TokenTransferUseCase');

      // 3. Sign transaction
      log('TokenTransferUseCase: Signing transaction', name: 'TokenTransferUseCase');
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
          log('TokenTransferUseCase: Signing failed: ${failure.message}', name: 'TokenTransferUseCase');
          return null;
        },
        (result) => result.serializedTx.isNotEmpty ? result.serializedTx : result.rawTx,
      );

      if (signedTx == null || signedTx.isEmpty) {
        return Left(ServerFailure(message: 'Signing failed'));
      }
      log('TokenTransferUseCase: signedTx=${signedTx.substring(0, 20)}...', name: 'TokenTransferUseCase');

      // 4. Send transaction
      log('TokenTransferUseCase: Sending transaction', name: 'TokenTransferUseCase');
      final sendResult = await _transactionRepository.sendTransaction(
        params: SendTransactionParams(
          network: params.transferParams.network,
          signedSerializeTx: signedTx,
        ),
      );

      return sendResult.fold(
        (failure) {
          log('TokenTransferUseCase: Send failed: ${failure.message}', name: 'TokenTransferUseCase');
          return Left(failure);
        },
        (result) {
          log('TokenTransferUseCase: Success! txHash=${result.transactionHash}',
              name: 'TokenTransferUseCase');
          return Right(TokenTransferResult(transactionHash: result.transactionHash));
        },
      );
    } catch (e) {
      log('TokenTransferUseCase: Exception: $e', name: 'TokenTransferUseCase');
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

/// Parameters for TokenTransferUseCase
class TokenTransferUseCaseParams extends Equatable {
  final TokenTransferParams transferParams;

  const TokenTransferUseCaseParams({required this.transferParams});

  @override
  List<Object?> get props => [transferParams];
}
