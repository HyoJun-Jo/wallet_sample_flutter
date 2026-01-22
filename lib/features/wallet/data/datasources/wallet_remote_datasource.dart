import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/wallet_model.dart';

/// Wallet Remote DataSource interface
abstract class WalletRemoteDataSource {
  /// Create and register wallet
  /// Uses WaaS MPC wallet API - creates EVM multi-chain wallet
  Future<WalletCreateResultModel> createWallet({
    required String email,
    required String encryptedPassword,
    required String secureChannelId,
  });

  /// Get wallet info (wid, uid, accounts)
  /// GET /wapi/v2/mpc/wallets/info
  Future<WalletInfoModel> getWalletInfo();

  /// Get V3 wallet info (includes Solana address)
  /// GET /v3/wallet
  Future<WalletV3InfoModel> getV3Wallet();

  /// Generate V3 wallet (ed25519 for Solana)
  /// POST /v3/wallet/generate
  Future<WalletV3KeyShareModel> generateV3Wallet({
    required String curve,
    required String encryptedPassword,
    required String secureChannelId,
  });

  /// Recover V3 wallet
  /// POST /v3/wallet/recover
  Future<WalletV3KeyShareModel> recoverV3Wallet({
    required String curve,
    required String encryptedPassword,
    required String secureChannelId,
  });
}

/// Wallet Remote DataSource implementation
class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient _apiClient;

  WalletRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<WalletCreateResultModel> createWallet({
    required String email,
    required String encryptedPassword,
    required String secureChannelId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.wallets,
        data: {
          'email': email,
          'devicePassword': encryptedPassword,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Secure-Channel': secureChannelId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return WalletCreateResultModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to create wallet',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw WalletException(message: e.toString());
    }
  }

  @override
  Future<WalletInfoModel> getWalletInfo() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.walletsInfo);

      if (response.statusCode == 200) {
        return WalletInfoModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to get wallet info',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw WalletException(message: e.toString());
    }
  }

  @override
  Future<WalletV3InfoModel> getV3Wallet() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.walletV3);

      if (response.statusCode == 200) {
        return WalletV3InfoModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to get V3 wallet',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw WalletException(message: e.toString());
    }
  }

  @override
  Future<WalletV3KeyShareModel> generateV3Wallet({
    required String curve,
    required String encryptedPassword,
    required String secureChannelId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.walletGenerateV3,
        data: {
          'curve': curve,
          'password': encryptedPassword,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'Secure-Channel': secureChannelId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return WalletV3KeyShareModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to generate V3 wallet',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw WalletException(message: e.toString());
    }
  }

  @override
  Future<WalletV3KeyShareModel> recoverV3Wallet({
    required String curve,
    required String encryptedPassword,
    required String secureChannelId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.walletRecoverV3,
        data: {
          'curve': curve,
          'password': encryptedPassword,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'Secure-Channel': secureChannelId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return WalletV3KeyShareModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to recover V3 wallet',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw WalletException(message: e.toString());
    }
  }
}
