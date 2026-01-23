import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/crypto/secure_channel_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../wallet/data/models/wallet_model.dart';
import '../../domain/entities/sign_request.dart';
import '../models/sign_request_model.dart';

/// Signing Remote DataSource interface
abstract class SigningRemoteDataSource {
  /// Sign message
  Future<SignResultModel> sign({
    required SignRequest request,
    required WalletCreateResultModel credentials,
  });

  /// Sign typed data (EIP-712)
  Future<SignResultModel> signTypedData({
    required TypedDataSignRequest request,
    required WalletCreateResultModel credentials,
  });

  /// Sign hash
  Future<SignResultModel> signHash({
    required HashSignRequest request,
    required WalletCreateResultModel credentials,
  });

  /// Sign EIP-1559 transaction
  Future<SignResultModel> signEip1559({
    required Eip1559SignRequest request,
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
  Future<SignResultModel> sign({
    required SignRequest request,
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
          'msg': request.msg,
          'network': request.network,
          'account_id': request.accountId,
          'msg_type': _msgTypeToString(request.msgType),
          'language': request.language,
          // Wallet credentials (encrypted with SecureChannel)
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
        return SignResultModel.fromJson(response.data);
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
  Future<SignResultModel> signTypedData({
    required TypedDataSignRequest request,
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

      final requestData = {
        'network': request.network,
        'messageJson': request.typeDataMsg,
        'version': 'v4', // EIP-712 version (v3 or v4)
        // Wallet credentials (encrypted with SecureChannel)
        'wid': encryptedWid,
        'uid': credentials.uid,
        'sid': credentials.sid,
        'pvencstr': encryptedPvencstr,
        'encryptDevicePassword': encryptedPassword,
      };

      developer.log('[SigningDataSource] signTypedData request:', name: 'SigningDataSource');
      developer.log('  network: ${request.network}', name: 'SigningDataSource');
      developer.log('  version: v4', name: 'SigningDataSource');
      developer.log('  messageJson length: ${request.typeDataMsg.length}', name: 'SigningDataSource');
      developer.log('  messageJson (first 200): ${request.typeDataMsg.substring(0, request.typeDataMsg.length > 200 ? 200 : request.typeDataMsg.length)}', name: 'SigningDataSource');

      final response = await _apiClient.post(
        ApiEndpoints.signTypedData,
        data: requestData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Secure-Channel': channel.channelId,
          },
        ),
      );

      developer.log('[SigningDataSource] signTypedData response: ${response.data}', name: 'SigningDataSource');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = SignResultModel.fromJson(response.data);
        developer.log('[SigningDataSource] signTypedData parsed:', name: 'SigningDataSource');
        developer.log('  signature: ${result.signature}', name: 'SigningDataSource');
        developer.log('  serializedTx: ${result.serializedTx}', name: 'SigningDataSource');
        developer.log('  rawTx: ${result.rawTx}', name: 'SigningDataSource');
        return result;
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
  Future<SignResultModel> signHash({
    required HashSignRequest request,
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
        ApiEndpoints.signHash,
        data: {
          'network': request.network,
          'account_id': request.accountId,
          'hash': request.hash,
          // Wallet credentials (encrypted with SecureChannel)
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
        return SignResultModel.fromJson(response.data);
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

  String _msgTypeToString(MessageType type) {
    switch (type) {
      case MessageType.transaction:
        return 'transaction';
      case MessageType.message:
        return 'message';
      case MessageType.typedData:
        return 'typed_data';
      case MessageType.hash:
        return 'hash';
    }
  }

  @override
  Future<SignResultModel> signEip1559({
    required Eip1559SignRequest request,
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
          'network': request.network,
          // Wallet credentials (encrypted with SecureChannel)
          'encryptDevicePassword': encryptedPassword,
          'pvencstr': encryptedPvencstr,
          'uid': credentials.uid,
          'wid': encryptedWid,
          'sid': credentials.sid,
          // Transaction params (camelCase to match Android)
          'to': request.to,
          'from': request.from,
          'value': request.value,
          'data': request.data,
          'nonce': request.nonce,
          'gasLimit': request.gasLimit,
          'maxPriorityFeePerGas': request.maxPriorityFeePerGas,
          'maxFeePerGas': request.maxFeePerGas,
          'type': 'EIP1559',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Secure-Channel': channel.channelId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SignResultModel.fromJson(response.data);
      }

      throw ServerException(
        message: 'Failed to sign EIP-1559 transaction',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw SigningException(message: e.toString());
    }
  }

}
