import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../../core/crypto/secure_channel_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/wallet/entities/wallet.dart';
import '../../../../core/wallet/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../models/wallet_model.dart';

/// Wallet Repository implementation
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;
  final SecureChannelService _secureChannelService;

  static const String _walletsKey = 'saved_wallets';
  static const String _keySharePrefix = 'keyshare_';
  static const String _v3KeySharePrefix = 'v3_keyshare_';

  WalletRepositoryImpl({
    required WalletRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
    required LocalStorageService localStorage,
    required SecureChannelService secureChannelService,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage,
        _localStorage = localStorage,
        _secureChannelService = secureChannelService;

  @override
  bool hasLocalWallets() {
    final walletsJson = _localStorage.getString(_walletsKey);
    if (walletsJson == null || walletsJson.isEmpty) return false;
    try {
      final List<dynamic> walletsList = jsonDecode(walletsJson);
      return walletsList.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Either<Failure, WalletCreateResult>> createWallet({
    required String email,
    required String password,
  }) async {
    try {
      // Encrypt password with SecureChannel
      final channel = await _secureChannelService.getOrCreateChannel();
      final encryptedPassword = _secureChannelService.encryptWithChannel(
        password,
        channel,
      );

      final result = await _remoteDataSource.createWallet(
        email: email,
        encryptedPassword: encryptedPassword,
        secureChannelId: channel.channelId,
      );

      // Save credentials from create response
      await _saveWalletCredentials(result);

      // Activate Solana (V3) wallet
      final solanaAddress = await _activateSolanaWallet(
        password: password,
        channel: channel,
        encryptedPassword: encryptedPassword,
      );

      // Add to wallet list (EVM multi-chain wallet with Solana)
      await _addWalletToList(WalletModel(
        address: result.address,
        name: null,
        network: 'evm', // Multi-chain EVM wallet
        createdAt: DateTime.now(),
        solanaAddress: solanaAddress,
      ));

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on WalletException catch (e) {
      return Left(WalletFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Save wallet credentials from create/recover response
  Future<void> _saveWalletCredentials(WalletCreateResultModel result) async {
    await _secureStorage.write(
      key: SecureStorageKeys.walletCredentials,
      value: result.toJsonString(),
    );
  }

  @override
  Future<Either<Failure, List<Wallet>>> getSavedWallets() async {
    try {
      final String? walletsJson = _localStorage.getString(_walletsKey);
      if (walletsJson == null || walletsJson.isEmpty) {
        return const Right([]);
      }

      final List<dynamic> walletsList = jsonDecode(walletsJson);
      final wallets = walletsList
          .map((json) => WalletModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(wallets);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveKeyShare({
    required String address,
    required String keyShare,
  }) async {
    try {
      await _saveKeyShareInternal(address, keyShare);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getKeyShare({
    required String address,
  }) async {
    try {
      final keyShare = await _secureStorage.read(
        key: '$_keySharePrefix$address',
      );
      return Right(keyShare);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  Future<void> _saveKeyShareInternal(String address, String keyShare) async {
    await _secureStorage.write(
      key: '$_keySharePrefix$address',
      value: keyShare,
    );
  }

  Future<void> _addWalletToList(WalletModel wallet) async {
    final String? walletsJson = _localStorage.getString(_walletsKey);
    List<dynamic> walletsList = [];

    if (walletsJson != null && walletsJson.isNotEmpty) {
      walletsList = jsonDecode(walletsJson);
    }

    walletsList.add(wallet.toJson());
    await _localStorage.setString(_walletsKey, jsonEncode(walletsList));
  }

  /// Activate Solana (V3) wallet - ed25519 curve
  /// Flow: Check V3 → generate/recover → Query V3 again → Extract Solana address
  Future<String?> _activateSolanaWallet({
    required String password,
    required dynamic channel,
    required String encryptedPassword,
  }) async {
    try {
      const curve = 'ed25519';
      WalletV3InfoModel? v3Info;
      bool hasEd25519 = false;

      // 1. Check if V3 wallet exists
      try {
        v3Info = await _remoteDataSource.getV3Wallet();
        hasEd25519 = v3Info.hasEd25519;
      } catch (e) {
        // V3_USER_NOT_FOUND - need to generate
      }

      // 2. Generate or recover V3 wallet
      if (v3Info == null || !hasEd25519) {
        // Generate new V3 wallet
        final keyShare = await _remoteDataSource.generateV3Wallet(
          curve: curve,
          encryptedPassword: encryptedPassword,
          secureChannelId: channel.channelId,
        );
        // Save V3 KeyShare
        await _saveV3KeyShare(curve, keyShare);
      } else {
        // Recover existing V3 wallet
        final keyShare = await _remoteDataSource.recoverV3Wallet(
          curve: curve,
          encryptedPassword: encryptedPassword,
          secureChannelId: channel.channelId,
        );
        // Save V3 KeyShare
        await _saveV3KeyShare(curve, keyShare);
      }

      // 3. Query V3 wallet again to get addresses
      final walletInfo = await _remoteDataSource.getV3Wallet();

      // 4. Extract Solana address from ed25519 wallet
      final ed25519Wallet = walletInfo.findByCurve(curve);
      final solanaAddress = ed25519Wallet?.solanaAddress;

      return solanaAddress;
    } catch (e) {
      // Solana activation failed, but EVM wallet creation succeeds
      // Return null to continue without Solana address
      return null;
    }
  }

  Future<void> _saveV3KeyShare(String curve, WalletV3KeyShareModel keyShare) async {
    await _secureStorage.write(
      key: '$_v3KeySharePrefix$curve',
      value: jsonEncode(keyShare.toJson()),
    );
  }

  @override
  Future<Either<Failure, void>> deleteWallet({
    required String address,
  }) async {
    try {
      // Remove from wallet list
      final String? walletsJson = _localStorage.getString(_walletsKey);
      if (walletsJson != null && walletsJson.isNotEmpty) {
        final List<dynamic> walletsList = jsonDecode(walletsJson);
        walletsList.removeWhere((json) => json['address'] == address);
        await _localStorage.setString(_walletsKey, jsonEncode(walletsList));
      }

      // Delete KeyShare
      await _secureStorage.delete(key: '$_keySharePrefix$address');

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletCredentials?>> getWalletCredentials() async {
    try {
      final jsonString = await _secureStorage.read(
        key: SecureStorageKeys.walletCredentials,
      );
      final model = WalletCreateResultModel.fromJsonString(jsonString);
      return Right(model?.toCredentialsEntity());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
