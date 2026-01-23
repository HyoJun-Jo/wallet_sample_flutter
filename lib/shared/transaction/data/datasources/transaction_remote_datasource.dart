import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/crypto/secure_channel_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/wallet/data/models/wallet_model.dart';
import '../../domain/entities/transaction_entities.dart';

/// Transaction Remote DataSource interface
abstract class TransactionRemoteDataSource {
  /// Get nonce for address
  Future<String> getNonce({
    required String address,
    required String network,
  });

  /// Get suggested gas fees (EIP-1559)
  Future<GasFees> getGasFees({
    required String network,
  });

  /// Estimate gas for transaction
  Future<String> estimateGas({
    required EstimateGasParams params,
  });

  /// Sign transaction (EIP-1559)
  Future<SignedTransaction> signTransaction({
    required SignTransactionParams params,
    required WalletCreateResultModel credentials,
  });

  /// Send signed transaction
  Future<String> sendTransaction({
    required SendTransactionParams params,
  });
}

/// Transaction Remote DataSource implementation
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient _apiClient;
  final SecureChannelService _secureChannelService;

  TransactionRemoteDataSourceImpl({
    required ApiClient apiClient,
    required SecureChannelService secureChannelService,
  })  : _apiClient = apiClient,
        _secureChannelService = secureChannelService;

  @override
  Future<String> getNonce({
    required String address,
    required String network,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.nonce,
        queryParameters: {
          'address': address,
          'network': network,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // Handle both direct value and nested response
        if (data is String) {
          return data;
        }
        final nonceValue = data['nonce']?.toString() ??
                          data['result']?.toString() ??
                          '0';
        // Convert to hex if needed
        if (nonceValue.startsWith('0x')) {
          return nonceValue;
        }
        final nonce = int.tryParse(nonceValue) ?? 0;
        return '0x${nonce.toRadixString(16)}';
      }

      throw ServerException(
        message: 'Failed to get nonce',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<GasFees> getGasFees({
    required String network,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.suggestGasFees,
        queryParameters: {
          'network': network,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Parse low, medium, high fee options
        final lowData = data['low'] as Map<String, dynamic>? ?? {};
        final mediumData = data['medium'] as Map<String, dynamic>? ?? {};
        final highData = data['high'] as Map<String, dynamic>? ?? {};
        final baseFee = data['estimatedBaseFee']?.toString() ?? '0';

        return GasFees(
          low: _parseGasFeeDetail(lowData),
          medium: _parseGasFeeDetail(mediumData),
          high: _parseGasFeeDetail(highData),
          baseFee: baseFee,
          network: network,
        );
      }

      throw ServerException(
        message: 'Failed to get gas fees',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  GasFeeDetail _parseGasFeeDetail(Map<String, dynamic> data) {
    final maxFee = data['suggestedMaxFeePerGas']?.toString() ?? '0';
    final maxPriority = data['suggestedMaxPriorityFeePerGas']?.toString() ?? '0';
    final time = data['minWaitTimeEstimate'] as int?;

    return GasFeeDetail(
      maxFeePerGas: _gweiToWeiHex(maxFee),
      maxPriorityFeePerGas: _gweiToWeiHex(maxPriority),
      estimatedTime: time,
    );
  }

  String _gweiToWeiHex(String gweiStr) {
    try {
      final gwei = double.tryParse(gweiStr) ?? 0;
      final wei = BigInt.from(gwei * 1e9);
      return '0x${wei.toRadixString(16)}';
    } catch (_) {
      return '0x0';
    }
  }

  @override
  Future<String> estimateGas({
    required EstimateGasParams params,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.estimateEip1559,
        data: {
          'network': params.network,
          'from': params.from,
          'to': params.to,
          'value': params.value ?? '0x0',
          'data': params.data ?? '0x',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final gasValue = data['result']?.toString() ??
                        data['gas']?.toString() ??
                        data['estimatedGas']?.toString();
        if (gasValue != null) {
          if (gasValue.startsWith('0x')) {
            return gasValue;
          }
          final gas = int.tryParse(gasValue) ?? 21000;
          return '0x${gas.toRadixString(16)}';
        }
      }

      throw ServerException(
        message: 'Failed to estimate gas',
        statusCode: response.statusCode,
      );
    } catch (e) {
      developer.log('Gas estimation failed: $e, using default', name: 'TransactionDataSource');
      // Default: 21000 for native, 90000 for contract calls
      final hasData = params.data != null && params.data != '0x';
      return hasData ? '0x15f90' : '0x5208';
    }
  }

  @override
  Future<SignedTransaction> signTransaction({
    required SignTransactionParams params,
    required WalletCreateResultModel credentials,
  }) async {
    try {
      // Get SecureChannel and encrypt credentials
      final channel = await _secureChannelService.getOrCreateChannel();
      final encryptedPassword = _secureChannelService.encryptWithChannel(
        credentials.encDevicePassword,
        channel,
      );
      final encryptedPvencstr = _secureChannelService.encryptWithChannel(
        credentials.pvencstr,
        channel,
      );
      final encryptedWid = _secureChannelService.encryptWithChannel(
        credentials.wid.toString(),
        channel,
      );

      final response = await _apiClient.post(
        ApiEndpoints.sign,
        data: {
          'network': params.network,
          // Wallet credentials (encrypted with SecureChannel)
          'encryptDevicePassword': encryptedPassword,
          'pvencstr': encryptedPvencstr,
          'uid': credentials.uid,
          'wid': encryptedWid,
          'sid': credentials.sid,
          // Transaction params
          'to': params.to,
          'from': params.from,
          'value': params.value,
          'data': params.data,
          'nonce': params.nonce,
          'gasLimit': params.gasLimit,
          'maxPriorityFeePerGas': params.maxPriorityFeePerGas,
          'maxFeePerGas': params.maxFeePerGas,
          'type': _signTypeToString(params.type),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Secure-Channel': channel.channelId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return SignedTransaction(
          signature: data['signature']?.toString() ?? '',
          serializedTx: data['serializedTx']?.toString(),
          rawTx: data['rawTx']?.toString(),
          txHash: data['txHash']?.toString(),
        );
      }

      throw ServerException(
        message: 'Failed to sign transaction',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  String _signTypeToString(SignType type) {
    switch (type) {
      case SignType.legacy:
        return 'LEGACY';
      case SignType.eip1559:
        return 'EIP1559';
      case SignType.personal:
        return 'PERSONAL';
    }
  }

  @override
  Future<String> sendTransaction({
    required SendTransactionParams params,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendTransaction,
        data: {
          'network': params.network,
          'signedSerializeTx': params.signedTx,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        developer.log('[TransactionDataSource] sendTransaction response: $data', name: 'TransactionDataSource');
        return data['result']?.toString() ??
               data['hash']?.toString() ??
               data['txHash']?.toString() ?? '';
      }

      throw ServerException(
        message: 'Failed to send transaction',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
