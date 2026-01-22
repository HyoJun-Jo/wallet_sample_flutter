import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/wei_utils.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/chain_service.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/transfer_remote_datasource.dart';
import '../models/transfer_model.dart';

/// Transfer Repository implementation
class TransferRepositoryImpl implements TransferRepository {
  final TransferRemoteDataSource _remoteDataSource;
  final ChainService _chainService;
  final ApiClient _apiClient;

  TransferRepositoryImpl({
    required TransferRemoteDataSource remoteDataSource,
    required ChainService chainService,
    required ApiClient apiClient,
  })  : _remoteDataSource = remoteDataSource,
        _chainService = chainService,
        _apiClient = apiClient;

  @override
  Future<Either<Failure, TransferData>> createTransferData({
    required TransferRequest request,
  }) async {
    try {
      final chain = _chainService.getByNetwork(request.network);
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

      // 3. Get gas fees (EIP-1559), nonce, and gasLimit from WaaS API
      final results = await Future.wait([
        _getSuggestedGasFees(request.network),
        _getNonce(request.fromAddress, request.network),
        _estimateGas(
          network: request.network,
          from: request.fromAddress,
          to: toAddress,
          value: value,
          data: data,
        ),
      ]);

      final gasFees = results[0] as Map<String, String>;
      final nonce = results[1] as String;
      final gasLimit = results[2] as String;
      log('gasFees: $gasFees, nonce: $nonce, gasLimit: $gasLimit', name: 'TransferRepository');

      final transferData = TransferDataModel(
        to: toAddress,
        from: request.fromAddress,
        data: data,
        value: value,
        gasLimit: gasLimit,
        maxFeePerGas: gasFees['maxFeePerGas']!,
        maxPriorityFeePerGas: gasFees['maxPriorityFeePerGas']!,
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

  /// Get suggested gas fees from WaaS API (EIP-1559)
  Future<Map<String, String>> _getSuggestedGasFees(String network) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.suggestGasFees,
        queryParameters: {'network': network},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // API returns { "medium": { "suggestedMaxFeePerGas": "...", "suggestedMaxPriorityFeePerGas": "..." } }
        final medium = data['medium'] as Map<String, dynamic>? ?? {};

        final maxFeePerGas = medium['suggestedMaxFeePerGas']?.toString() ?? '0';
        final maxPriorityFeePerGas = medium['suggestedMaxPriorityFeePerGas']?.toString() ?? '0';

        return {
          'maxFeePerGas': WeiUtils.gweiToWeiHex(maxFeePerGas),
          'maxPriorityFeePerGas': WeiUtils.gweiToWeiHex(maxPriorityFeePerGas),
        };
      }
    } catch (e) {
      log('Failed to get suggested gas fees: $e', name: 'TransferRepository');
    }
    // Default: 30 gwei maxFee, 1.5 gwei priority
    return {
      'maxFeePerGas': '0x6fc23ac00', // 30 gwei
      'maxPriorityFeePerGas': '0x59682f00', // 1.5 gwei
    };
  }

  /// Get nonce from WaaS API
  Future<String> _getNonce(String address, String network) async {
    final response = await _apiClient.get(
      ApiEndpoints.nonce,
      queryParameters: {
        'address': address,
        'network': network,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      // API returns { "result": "0x..." } or { "nonce": "0x..." }
      final nonceValue = data['result']?.toString() ??
                         data['nonce']?.toString() ??
                         '0';
      // Convert to hex if needed
      if (nonceValue.startsWith('0x')) {
        return nonceValue;
      }
      final nonce = int.tryParse(nonceValue) ?? 0;
      return '0x${nonce.toRadixString(16)}';
    }
    throw ServerException(message: 'Failed to get nonce');
  }

  /// Estimate gas from WaaS API (EIP-1559)
  Future<String> _estimateGas({
    required String network,
    required String from,
    required String to,
    required String value,
    required String data,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.estimateEip1559,
        data: {
          'network': network,
          'from': from,
          'to': to,
          'value': value,
          'data': data,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        // API returns { "result": "0x..." } or { "gas": "..." }
        final gasValue = responseData['result']?.toString() ??
                         responseData['gas']?.toString() ??
                         responseData['estimatedGas']?.toString();
        if (gasValue != null) {
          if (gasValue.startsWith('0x')) {
            return gasValue;
          }
          final gas = int.tryParse(gasValue) ?? 21000;
          return '0x${gas.toRadixString(16)}';
        }
      }
    } catch (e) {
      log('Gas estimation failed: $e, using default', name: 'TransferRepository');
    }
    // Default: 21000 for native, 90000 for contract calls
    return data == '0x' ? '0x5208' : '0x15f90';
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
