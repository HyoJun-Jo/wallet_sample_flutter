import '../../../../core/storage/secure_storage.dart';
import '../models/wallet_create_model.dart';

/// Wallet Local DataSource interface
abstract class WalletLocalDataSource {
  /// Check if wallet credentials exist
  Future<bool> hasCredentials();

  /// Get saved wallet credentials
  Future<WalletCreateModel?> getCredentials();

  /// Save wallet credentials
  Future<void> saveCredentials(WalletCreateModel credentials);

  /// Delete wallet credentials
  Future<void> deleteCredentials();
}

/// Wallet Local DataSource implementation
class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  final SecureStorageService _secureStorage;

  WalletLocalDataSourceImpl({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  @override
  Future<bool> hasCredentials() async {
    final jsonString = await _secureStorage.read(
      key: SecureStorageKeys.walletCredentials,
    );
    return jsonString != null && jsonString.isNotEmpty;
  }

  @override
  Future<WalletCreateModel?> getCredentials() async {
    final jsonString = await _secureStorage.read(
      key: SecureStorageKeys.walletCredentials,
    );
    return WalletCreateModel.fromJsonString(jsonString);
  }

  @override
  Future<void> saveCredentials(WalletCreateModel credentials) async {
    await _secureStorage.write(
      key: SecureStorageKeys.walletCredentials,
      value: credentials.toJsonString(),
    );
  }

  @override
  Future<void> deleteCredentials() async {
    await _secureStorage.delete(key: SecureStorageKeys.walletCredentials);
  }
}
