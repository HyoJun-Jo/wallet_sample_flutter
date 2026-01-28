import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/history_model.dart';

abstract class HistoryRemoteDataSource {
  Future<List<HistoryModel>> getHistory({
    required String walletAddress,
    required String networks,
    int? epochSince,
  });
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final ApiClient _apiClient;

  HistoryRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<HistoryModel>> getHistory({
    required String walletAddress,
    required String networks,
    int? epochSince,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.transactions,
        queryParameters: {
          'walletAddress': walletAddress,
          'networks': networks,
          if (epochSince != null) 'epochSince': epochSince,
        },
      );

      if (response.statusCode == 200) {
        final list = _parseHistoryList(response.data);
        return list
            .map((json) => HistoryModel.fromJson(json, walletAddress))
            .toList();
      }

      throw ServerException(
        message: 'Failed to get history',
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  List<Map<String, dynamic>> _parseHistoryList(dynamic data) {
    if (data is String) {
      data = jsonDecode(data);
    }

    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }

    if (data is Map<String, dynamic>) {
      final transactions = data['transactions'];
      if (transactions is List) {
        return transactions.cast<Map<String, dynamic>>();
      }
      throw FormatException('Expected "transactions" key in response');
    }

    throw FormatException('Unexpected response format: ${data.runtimeType}');
  }
}
