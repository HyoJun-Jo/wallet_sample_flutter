import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/token_transfer.dart';
import '../models/token_info_model.dart';

abstract class TokenRemoteDataSource {
  Future<List<TokenInfoModel>> getAllTokens({
    required String walletAddress,
    required String networks,
    bool minimalInfo = false,
  });

  Future<TokenTransferDataResult> getTransferData({
    required GetTokenTransferDataParams params,
  });
}

class TokenRemoteDataSourceImpl implements TokenRemoteDataSource {
  final ApiClient _apiClient;

  TokenRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<TokenInfoModel>> getAllTokens({
    required String walletAddress,
    required String networks,
    bool minimalInfo = false,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.tokens,
        queryParameters: {
          'walletAddress': walletAddress,
          'networks': networks,
          'minimalInfo': minimalInfo,
        },
      );

      if (response.statusCode == 200) {
        final tokensList = _parseTokenList(response.data);
        return tokensList
            .map((json) => TokenInfoModel.fromJson(json))
            .toList();
      }

      throw ServerException(
        message: 'Failed to get tokens',
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TokenTransferDataResult> getTransferData({
    required GetTokenTransferDataParams params,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.tokenTransferData,
        queryParameters: {
          'network': params.network,
          'to': params.to,
          'value': params.value,
          if (params.from != null && params.from!.isNotEmpty) 'from': params.from,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TokenTransferDataResult(data: response.data['result'] as String);
      }

      throw ServerException(
        message: 'Failed to get transfer data',
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  List<Map<String, dynamic>> _parseTokenList(dynamic data) {
    if (data is String) {
      data = jsonDecode(data);
    }

    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }

    if (data is Map<String, dynamic>) {
      final tokens = data['tokens'];
      if (tokens is List) {
        return tokens.cast<Map<String, dynamic>>();
      }
    }

    return [];
  }
}
