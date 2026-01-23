import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/transfer.dart';
import '../models/token_info_model.dart';
import '../models/transfer_model.dart';

/// Token Remote DataSource interface
abstract class TokenRemoteDataSource {
  /// Get all tokens for a wallet (EVM only, single API call)
  /// Returns native + ERC-20 tokens with prices
  /// [networks] - comma-separated network names (e.g., "ethereum,polygon,binance")
  /// [minimalInfo] - if true, returns minimal token info (faster response)
  Future<List<TokenInfoModel>> getAllTokens({
    required String walletAddress,
    required String networks,
    bool minimalInfo = false,
  });

  /// Get token allowance
  Future<TokenAllowanceModel> getAllowance({
    required String contractAddress,
    required String ownerAddress,
    required String spenderAddress,
    required String network,
  });

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

/// Token Remote DataSource implementation
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
        dynamic data = response.data;

        // Parse JSON string if needed
        if (data is String) {
          data = jsonDecode(data);
        }

        // Handle both array response and object with 'tokens' field
        List<dynamic> tokensList;
        if (data is List) {
          tokensList = data;
        } else if (data is Map<String, dynamic>) {
          tokensList = data['tokens'] as List<dynamic>? ?? [];
        } else {
          tokensList = [];
        }

        log('Tokens list length: ${tokensList.length}', name: 'TokenDataSource');

        final result = <TokenInfoModel>[];
        for (int i = 0; i < tokensList.length; i++) {
          try {
            final json = tokensList[i] as Map<String, dynamic>;
            result.add(TokenInfoModel.fromJson(json));
          } catch (e) {
            log('Error parsing token[$i]: $e', name: 'TokenDataSource');
            log('Token data: ${tokensList[i]}', name: 'TokenDataSource');
          }
        }
        return result;
      }

      throw ServerException(
        message: 'Failed to get all tokens',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TokenAllowanceModel> getAllowance({
    required String contractAddress,
    required String ownerAddress,
    required String spenderAddress,
    required String network,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.tokenAllowance,
        queryParameters: {
          'contract_address': contractAddress,
          'owner': ownerAddress,
          'spender': spenderAddress,
          'network': network,
        },
      );

      if (response.statusCode == 200) {
        return TokenAllowanceModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to get allowance',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

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
