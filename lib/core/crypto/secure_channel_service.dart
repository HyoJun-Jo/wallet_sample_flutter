import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pointycastle/export.dart';

import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import 'secure_channel.dart';

/// Secure Channel Service
/// Manages ECDH key exchange with server and encrypts sensitive data
class SecureChannelService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;
  final SecureChannel _secureChannel;

  SecureChannelData? _cachedChannel;

  SecureChannelService({
    required ApiClient apiClient,
    required SecureStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage,
        _secureChannel = SecureChannel.instance;

  /// Get or create a valid secure channel
  /// Returns cached channel if not expired, otherwise creates a new one
  Future<SecureChannelData> getOrCreateChannel({int expireMinutes = 20}) async {
    // Check cached channel first
    if (_cachedChannel != null && !_cachedChannel!.isExpired(expireMinutes: expireMinutes)) {
      return _cachedChannel!;
    }

    // Try to load from storage
    final stored = await _loadChannelFromStorage();
    if (stored != null && !stored.isExpired(expireMinutes: expireMinutes)) {
      _cachedChannel = stored;
      return stored;
    }

    // Create new channel
    return await createChannel();
  }

  /// Create a new secure channel with the server
  Future<SecureChannelData> createChannel() async {
    developer.log('SecureChannel: Creating new channel', name: 'SecureChannel');

    // 1. Generate client key pair
    final keyPair = _secureChannel.generateKeyPair();
    final clientPrivateKey = keyPair.privateKey as ECPrivateKey;
    final clientPublicKey = keyPair.publicKey as ECPublicKey;

    // 2. Serialize public key to uncompressed format
    final clientPublicKeyHex = _secureChannel.serializeUncompressedPublicKey(clientPublicKey);

    // 3. Generate random string for verification
    final randomString = _secureChannel.generateRandomString(20);

    // 4. Request secure channel from server
    final response = await _requestSecureChannel(
      publicKey: clientPublicKeyHex,
      plain: randomString,
    );

    // 5. Parse server public key
    final serverPublicKey = _secureChannel.createPublicKeyFromUncompressed(
      response.serverPublicKey,
    );

    // 6. Compute shared secret using ECDH
    final sharedSecret = _secureChannel.computeSharedSecret(
      serverPublicKey,
      clientPrivateKey,
    );

    // 7. Verify by decrypting the encrypted random string
    final decrypted = _secureChannel.decryptBase64(response.encrypted, sharedSecret);
    if (decrypted != randomString) {
      throw ServerException(
        message: 'Secure channel verification failed',
        statusCode: 400,
      );
    }

    // 8. Create and cache channel data
    final channelData = SecureChannelData(
      channelId: response.channelId,
      sharedSecret: sharedSecret,
      createdAt: DateTime.now(),
    );

    _cachedChannel = channelData;
    await _saveChannelToStorage(channelData);
    developer.log('SecureChannel: Channel created (${channelData.channelId})', name: 'SecureChannel');

    return channelData;
  }

  /// Encrypt plaintext using the current secure channel
  Future<String> encrypt(String plaintext) async {
    final channel = await getOrCreateChannel();
    return _secureChannel.encrypt(plaintext, channel.sharedSecret);
  }

  /// Encrypt plaintext with a specific channel
  String encryptWithChannel(String plaintext, SecureChannelData channel) {
    return _secureChannel.encrypt(plaintext, channel.sharedSecret);
  }

  /// Decrypt ciphertext using the current secure channel
  Future<String> decrypt(Uint8List encrypted) async {
    final channel = await getOrCreateChannel();
    return _secureChannel.decrypt(encrypted, channel.sharedSecret);
  }

  /// Get the current channel ID (for API headers)
  Future<String> getChannelId() async {
    final channel = await getOrCreateChannel();
    return channel.channelId;
  }

  /// Clear the cached channel (e.g., on logout)
  Future<void> clearChannel() async {
    _cachedChannel = null;
    await _storage.delete(key: SecureStorageKeys.secureChannelData);
  }

  Future<_SecureChannelResponse> _requestSecureChannel({
    required String publicKey,
    required String plain,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.secureChannelCreate,
        data: {
          'pubkey': publicKey,
          'plain': plain,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          extra: {'skipAuth': true},
        ),
      );

      final data = response.data;

      if (data['error'] != null) {
        throw ServerException(
          message: data['error']['message'] ?? 'Secure channel creation failed',
          statusCode: response.statusCode,
        );
      }

      return _SecureChannelResponse(
        channelId: data['channelid'] as String,
        serverPublicKey: data['publickey'] as String,
        encrypted: data['encrypted'] as String,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Secure channel request failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<SecureChannelData?> _loadChannelFromStorage() async {
    final jsonStr = await _storage.read(key: SecureStorageKeys.secureChannelData);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SecureChannelData.fromJson(json);
    } catch (e) {
      developer.log('Failed to load channel from storage: $e', name: 'SecureChannel');
      return null;
    }
  }

  Future<void> _saveChannelToStorage(SecureChannelData channel) async {
    final jsonStr = jsonEncode(channel.toJson());
    await _storage.write(key: SecureStorageKeys.secureChannelData, value: jsonStr);
  }
}

/// Internal response class for secure channel API
class _SecureChannelResponse {
  final String channelId;
  final String serverPublicKey;
  final String encrypted;

  _SecureChannelResponse({
    required this.channelId,
    required this.serverPublicKey,
    required this.encrypted,
  });
}
