import 'dart:convert';
import 'dart:developer';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/transaction_history_model.dart';

/// History Remote DataSource interface
abstract class HistoryRemoteDataSource {
  /// Get all transactions for a wallet
  /// [networks] - comma-separated network names (e.g., "ethereum,polygon,binance")
  Future<List<TransactionHistoryModel>> getTransactions({
    required String walletAddress,
    required String networks,
  });
}

/// History Remote DataSource implementation
class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final ApiClient _apiClient;

  HistoryRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<TransactionHistoryModel>> getTransactions({
    required String walletAddress,
    required String networks,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.transactions,
        queryParameters: {
          'walletAddress': walletAddress,
          'networks': networks,
        },
      );

      if (response.statusCode == 200) {
        dynamic data = response.data;

        log('Raw response data: $data', name: 'HistoryDataSource');

        // Parse JSON string if needed
        if (data is String) {
          data = jsonDecode(data);
        }

        log('Response type: ${data.runtimeType}', name: 'HistoryDataSource');
        if (data is Map<String, dynamic>) {
          log('Response keys: ${data.keys.toList()}', name: 'HistoryDataSource');
          // Check all possible keys
          data.forEach((key, value) {
            if (value is List) {
              log('Key "$key" is List with ${value.length} items',
                  name: 'HistoryDataSource');
            }
          });
        }

        // Handle both array response and object with various field names
        List<dynamic> txList;
        if (data is List) {
          txList = data;
        } else if (data is Map<String, dynamic>) {
          // Try multiple possible field names
          txList = data['transactions'] as List<dynamic>? ??
              data['result'] as List<dynamic>? ??
              data['data'] as List<dynamic>? ??
              data['items'] as List<dynamic>? ??
              data['list'] as List<dynamic>? ??
              [];
        } else {
          txList = [];
        }

        log('Transactions list length: ${txList.length}',
            name: 'HistoryDataSource');
        if (txList.isNotEmpty) {
          log('First transaction: ${txList.first}', name: 'HistoryDataSource');
        }

        final result = <TransactionHistoryModel>[];
        for (int i = 0; i < txList.length; i++) {
          try {
            final json = txList[i] as Map<String, dynamic>;
            result.add(TransactionHistoryModel.fromJson(json, walletAddress));
          } catch (e) {
            log('Error parsing transaction[$i]: $e', name: 'HistoryDataSource');
            log('Transaction data: ${txList[i]}', name: 'HistoryDataSource');
          }
        }
        return result;
      }

      throw ServerException(
        message: 'Failed to get transactions',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
