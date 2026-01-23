import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/transaction_entities.dart';
import '../models/transaction_models.dart';

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

  /// Send signed transaction
  Future<String> sendTransaction({
    required SendTransactionParams params,
  });
}

/// Transaction Remote DataSource implementation
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient _apiClient;

  TransactionRemoteDataSourceImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

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
        final model = GasFeesModel.fromJson(response.data as Map<String, dynamic>);
        return model.toEntity(network);
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
  Future<String> sendTransaction({
    required SendTransactionParams params,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendTransaction,
        data: {
          'network': params.network,
          'signedSerializeTx': params.signedSerializeTx,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('[TransactionDataSource] sendTransaction response: ${response.data}', name: 'TransactionDataSource');
        final model = TransactionResultModel.fromJson(response.data as Map<String, dynamic>);
        return model.result;
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
