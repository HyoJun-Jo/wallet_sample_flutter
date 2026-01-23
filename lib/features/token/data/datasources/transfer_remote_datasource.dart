import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/transfer.dart';
import '../models/transfer_model.dart';

/// Transfer Remote DataSource interface
abstract class TransferRemoteDataSource {
  /// Get ABI data for ERC-20 token transfer
  Future<String> getTokenTransferAbiData({
    required TransferRequest request,
  });

  /// Send raw transaction
  Future<TransferResultModel> sendTransaction({
    required String network,
    required String rawData,
  });
}

/// Transfer Remote DataSource implementation
class TransferRemoteDataSourceImpl implements TransferRemoteDataSource {
  final ApiClient _apiClient;

  TransferRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<String> getTokenTransferAbiData({
    required TransferRequest request,
  }) async {
    try {
      // Convert amount to hex value
      final amountBigInt = BigInt.tryParse(request.amount) ?? BigInt.zero;
      final hexValue = '0x${amountBigInt.toRadixString(16)}';

      final response = await _apiClient.get(
        ApiEndpoints.tokenTransferData,
        queryParameters: {
          if (request.fromAddress.isNotEmpty) 'from': request.fromAddress,
          'to': request.toAddress,
          'value': hexValue,
          'network': request.network,
          'contract_address': request.contractAddress,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // API returns { "result": "0x..." }
        return response.data['result'] as String;
      }

      throw ServerException(
        message: 'Failed to get transfer abi data',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TransferResultModel> sendTransaction({
    required String network,
    required String rawData,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendTransaction,
        data: {
          'network': network,
          'raw_data': rawData,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransferResultModel.fromJson(response.data);
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
