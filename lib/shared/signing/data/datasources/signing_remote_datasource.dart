import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/crypto/secure_channel_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/wallet/data/models/wallet_model.dart';
import '../../domain/entities/signing_entities.dart';
import '../models/signing_models.dart';

/// Signing Remote DataSource interface
abstract class SigningRemoteDataSource {
  /// Personal sign
  Future<SignResponseModel> personalSign({
    required PersonalSignParams params,
    required WalletCreateResultModel credentials,
  });

  /// Sign typed data (EIP-712)
  Future<SignResponseModel> signTypedData({
    required SignTypedDataParams params,
    required WalletCreateResultModel credentials,
  });

  /// Sign hash
  Future<SignResponseModel> signHash({
    required SignHashParams params,
    required WalletCreateResultModel credentials,
  });

  /// Sign transaction
  Future<SignResponseModel> signTransaction({
    required SignTransactionParams params,
    required WalletCreateResultModel credentials,
  });
}

/// Signing Remote DataSource implementation
class SigningRemoteDataSourceImpl implements SigningRemoteDataSource {
  final ApiClient _apiClient;
  final SecureChannelService _secureChannelService;

  SigningRemoteDataSourceImpl({
    required ApiClient apiClient,
    required SecureChannelService secureChannelService,
  })  : _apiClient = apiClient,
        _secureChannelService = secureChannelService;

  @override
  Future<SignResponseModel> personalSign({
    required PersonalSignParams params,
    required WalletCreateResultModel credentials,
  }) async {
    try {
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
          'message': params.message,
          'type': 'PERSONAL',
          'wid': encryptedWid,
          'uid': credentials.uid,
          'sid': credentials.sid,
          'pvencstr': encryptedPvencstr,
          'encryptDevicePassword': encryptedPassword,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Secure-Channel': channel.channelId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SignResponseModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to sign',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw SigningException(message: e.toString());
    }
  }

  @override
  Future<SignResponseModel> signTypedData({
    required SignTypedDataParams params,
    required WalletCreateResultModel credentials,
  }) async {
    try {
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
        ApiEndpoints.signTypedData,
        data: {
          'network': params.network,
          'messageJson': params.messageJson,
          'version': params.version,
          'wid': encryptedWid,
          'uid': credentials.uid,
          'sid': credentials.sid,
          'pvencstr': encryptedPvencstr,
          'encryptDevicePassword': encryptedPassword,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Secure-Channel': channel.channelId,
          },
        ),
      );

      developer.log('[SigningDataSource] signTypedData response: ${response.data}', name: 'SigningDataSource');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SignResponseModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to sign typed data',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw SigningException(message: e.toString());
    }
  }

  @override
  Future<SignResponseModel> signHash({
    required SignHashParams params,
    required WalletCreateResultModel credentials,
  }) async {
    try {
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
        ApiEndpoints.signHash,
        data: {
          'network': params.network,
          'hash': params.hash,
          'wid': encryptedWid,
          'uid': credentials.uid,
          'sid': credentials.sid,
          'pvencstr': encryptedPvencstr,
          'encryptDevicePassword': encryptedPassword,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Secure-Channel': channel.channelId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SignResponseModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to sign hash',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw SigningException(message: e.toString());
    }
  }

  @override
  Future<SignResponseModel> signTransaction({
    required SignTransactionParams params,
    required WalletCreateResultModel credentials,
  }) async {
    try {
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
          'encryptDevicePassword': encryptedPassword,
          'pvencstr': encryptedPvencstr,
          'uid': credentials.uid,
          'wid': encryptedWid,
          'sid': credentials.sid,
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
        return SignResponseModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to sign transaction',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw SigningException(message: e.toString());
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
}
