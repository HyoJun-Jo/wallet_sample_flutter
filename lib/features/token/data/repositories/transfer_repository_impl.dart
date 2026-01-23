import 'dart:developer';

import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/chain/chain_repository.dart';
import '../../../../shared/transaction/domain/entities/transaction_entities.dart';
import '../../../../shared/transaction/domain/repositories/transaction_repository.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/token_remote_datasource.dart';
import '../models/transfer_model.dart';

class TransferRepositoryImpl implements TransferRepository {
  final TokenRemoteDataSource _remoteDataSource;
  final ChainRepository _chainRepository;
  final TransactionRepository _transactionRepository;

  TransferRepositoryImpl({
    required TokenRemoteDataSource remoteDataSource,
    required ChainRepository chainService,
    required TransactionRepository transactionRepository,
  })  : _remoteDataSource = remoteDataSource,
        _chainRepository = chainService,
        _transactionRepository = transactionRepository;

  @override
  Future<Either<Failure, TransferData>> createTransferData({
    required TransferRequest request,
  }) async {
    try {
      final chain = _chainRepository.getByNetwork(request.network);
      if (chain == null) {
        return Left(ServerFailure(message: 'Unknown network: ${request.network}'));
      }

      final isNative = request.contractAddress.isEmpty;
      log('Transfer: ${request.network}, isNative=$isNative', name: 'TransferRepository');

      // 1. Get abiData (only for ERC-20)
      // Use empty fromAddress to get transfer() ABI instead of transferFrom()
      String abiData = '0x';
      if (!isNative) {
        final transferRequest = TransferRequest(
          fromAddress: '', // Empty to get transfer() ABI
          toAddress: request.toAddress,
          amount: request.amount,
          contractAddress: request.contractAddress,
          network: request.network,
        );
        abiData = await _remoteDataSource.getTokenTransferAbiData(request: transferRequest);
        log('ERC-20 abiData: $abiData', name: 'TransferRepository');
      }

      // 2. Prepare transaction params
      final String toAddress;
      final String value;
      final String data;

      if (isNative) {
        // Native transfer: to = recipient, value = amount
        toAddress = request.toAddress;
        value = _toWei(request.amount, chain.decimals);
        data = '0x';
      } else {
        // ERC-20 transfer: to = contract, value = 0, data = abiData
        toAddress = request.contractAddress;
        value = '0x0';
        data = abiData;
      }

      // 3. Get gas fees (EIP-1559), nonce, and gasLimit via TransactionRepository
      final results = await Future.wait([
        _transactionRepository.getGasFees(network: request.network),
        _transactionRepository.getNonce(address: request.fromAddress, network: request.network),
        _transactionRepository.estimateGas(
          params: EstimateGasParams(
            network: request.network,
            from: request.fromAddress,
            to: toAddress,
            value: value,
            data: data,
          ),
        ),
      ]);

      final gasFeesResult = results[0] as Either<Failure, GasFees>;
      final nonceResult = results[1] as Either<Failure, String>;
      final gasLimitResult = results[2] as Either<Failure, EstimateGasResult>;

      // 결과 추출 (실패 시 기본값 사용)
      final gasFees = gasFeesResult.fold(
        (failure) => null,
        (fees) => fees,
      );
      final nonce = nonceResult.fold(
        (failure) => '0x0',
        (n) => n,
      );
      final gasLimit = gasLimitResult.fold(
        (failure) => data == '0x' ? '0x5208' : '0x15f90',
        (result) => result.gasLimit,
      );

      // gasFees 실패 시 기본값
      final maxFeePerGas = gasFees?.medium.maxFeePerGas ?? '0x6fc23ac00';
      final maxPriorityFeePerGas = gasFees?.medium.maxPriorityFeePerGas ?? '0x59682f00';

      log('gasFees: $gasFees, nonce: $nonce, gasLimit: $gasLimit', name: 'TransferRepository');

      final transferData = TransferDataModel(
        to: toAddress,
        from: request.fromAddress,
        data: data,
        value: value,
        gasLimit: gasLimit,
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        nonce: nonce,
        network: request.network,
      );

      log('TransferData: to=$toAddress, from=${request.fromAddress}, value=$value, gasLimit=$gasLimit',
          name: 'TransferRepository');

      return Right(transferData);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      log('Transfer error: $e', name: 'TransferRepository');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Convert amount string to wei (hex string)
  String _toWei(String amount, int decimals) {
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

  @override
  Future<Either<Failure, TransferResult>> sendTransaction({
    required String network,
    required String rawData,
  }) async {
    try {
      final result = await _remoteDataSource.sendTransaction(
        network: network,
        rawData: rawData,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
