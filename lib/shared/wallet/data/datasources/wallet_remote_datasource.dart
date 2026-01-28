import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/crypto/secure_channel_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/wallet_create_model.dart';
import '../models/wallet_info_model.dart';
import '../models/wallet_v3_info_model.dart';

/// Wallet Remote DataSource interface
abstract class WalletRemoteDataSource {
  /// Create EVM wallet
  Future<WalletCreateModel> createWallet({
    required String email,
    required String password,
  });

  /// Get wallet info (wid, uid, accounts)
  Future<WalletInfoModel> getWalletInfo();

  /// Get V3 wallet info (includes Solana address)
  Future<WalletV3InfoModel> getV3Wallet();

  /// Generate V3 wallet (ed25519 for Solana)
  Future<Ed25519KeyShareInfoModel> generateV3Wallet({
    required String curve,
    required String password,
  });

  /// Recover V3 wallet
  Future<Ed25519KeyShareInfoModel> recoverV3Wallet({
    required String curve,
    required String password,
  });

  /// Lookup BTC address from pubkey
  Future<String> lookupBtcAddress({
    required String pubkey,
    required String network,
  });
}

/// Wallet Remote DataSource implementation
class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient _apiClient;
  final SecureChannelService _secureChannelService;

  WalletRemoteDataSourceImpl({
    required ApiClient apiClient,
    required SecureChannelService secureChannelService,
  })  : _apiClient = apiClient,
        _secureChannelService = secureChannelService;

  /// Encrypt password with secure channel
  Future<(String encryptedPassword, String channelId)> _encryptPassword(
      String password) async {
    final channel = await _secureChannelService.getOrCreateChannel();
    final encryptedPassword = _secureChannelService.encryptWithChannel(
      password,
      channel,
    );
    return (encryptedPassword, channel.channelId);
  }

  @override
  Future<WalletCreateModel> createWallet({
    required String email,
    required String password,
  }) async {
    try {
      final (encryptedPassword, channelId) = await _encryptPassword(password);

      final response = await _apiClient.post(
        ApiEndpoints.wallets,
        data: {
          'email': email,
          'devicePassword': encryptedPassword,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Secure-Channel': channelId},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // API 응답 필드명 매핑: sid→address, pvencstr→keyShare 등
        final data = response.data as Map<String, dynamic>;
        return WalletCreateModel(
          address: data['sid'] as String,
          keyShare: data['pvencstr'] as String,
          uid: data['uid'] as String,
          wid: data['wid'] as int,
          encDevicePassword: data['encryptDevicePassword'] as String,
        );
      }

      throw ServerException(
        message: 'Failed to create wallet',
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
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
    } on ServerException {
      rethrow;
    } catch (e) {
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
    } on ServerException {
      rethrow;
    } catch (e) {
      throw WalletException(message: e.toString());
    }
  }

  @override
  Future<Ed25519KeyShareInfoModel> generateV3Wallet({
    required String curve,
    required String password,
  }) async {
    try {
      final (encryptedPassword, channelId) = await _encryptPassword(password);

      final response = await _apiClient.post(
        ApiEndpoints.walletGenerateV3,
        data: {
          'curve': curve,
          'password': encryptedPassword,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {'Secure-Channel': channelId},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Ed25519KeyShareInfoModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to generate V3 wallet',
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw WalletException(message: e.toString());
    }
  }

  @override
  Future<Ed25519KeyShareInfoModel> recoverV3Wallet({
    required String curve,
    required String password,
  }) async {
    try {
      final (encryptedPassword, channelId) = await _encryptPassword(password);

      final response = await _apiClient.post(
        ApiEndpoints.walletRecoverV3,
        data: {
          'curve': curve,
          'password': encryptedPassword,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {'Secure-Channel': channelId},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Ed25519KeyShareInfoModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to recover V3 wallet',
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw WalletException(message: e.toString());
    }
  }

  @override
  Future<String> lookupBtcAddress({
    required String pubkey,
    required String network,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.btcAddress}?pubkey=$pubkey&network=$network',
      );

      if (response.statusCode == 200) {
        return response.data['address'] as String;
      }

      throw ServerException(
        message: 'Failed to lookup BTC address',
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw WalletException(message: e.toString());
    }
  }
}
