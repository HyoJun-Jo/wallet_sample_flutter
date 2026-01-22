import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage keys
class SecureStorageKeys {
  SecureStorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String secureChannelId = 'secure_channel_id';
  static const String secureChannelData = 'secure_channel_data';

  // Wallet credentials (uid, wid, sid, password, pvencstr)
  static const String walletCredentials = 'wallet_credentials';

  // User credentials for auto login
  static const String userPassword = 'user_password';
}

/// Secure Storage service
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // Helper methods for common operations
  Future<String?> getAccessToken() async {
    return await read(key: SecureStorageKeys.accessToken);
  }

  Future<void> setAccessToken(String token) async {
    await write(key: SecureStorageKeys.accessToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await read(key: SecureStorageKeys.refreshToken);
  }

  Future<void> setRefreshToken(String token) async {
    await write(key: SecureStorageKeys.refreshToken, value: token);
  }

  Future<String?> getUserPassword() async {
    return await read(key: SecureStorageKeys.userPassword);
  }

  Future<void> setUserPassword(String password) async {
    await write(key: SecureStorageKeys.userPassword, value: password);
  }

  Future<void> deleteUserPassword() async {
    await delete(key: SecureStorageKeys.userPassword);
  }
}
