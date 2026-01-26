import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/wallet_create_model.dart';
import '../../data/models/wallet_info_model.dart';
import '../../data/models/wallet_v3_info_model.dart';
import '../entities/wallet_credentials.dart';

/// Wallet Repository interface
abstract class WalletRepository {
  /// Check if wallet credentials exist locally
  Future<bool> checkWallet();

  /// Create EVM wallet
  Future<Either<Failure, WalletCreateModel>> createWallet({
    required String email,
    required String password,
  });

  /// Get wallet info (for pubkey)
  Future<Either<Failure, WalletInfoModel>> getWalletInfo();

  /// Lookup BTC address from pubkey
  Future<Either<Failure, String>> lookupBtcAddress({
    required String pubkey,
    required String network,
  });

  /// Get V3 wallet info
  Future<Either<Failure, WalletV3InfoModel>> getV3Wallet();

  /// Generate V3 wallet (ed25519 for Solana)
  Future<Either<Failure, Ed25519KeyShareInfoModel>> generateV3Wallet({
    required String curve,
    required String password,
  });

  /// Recover V3 wallet
  Future<Either<Failure, Ed25519KeyShareInfoModel>> recoverV3Wallet({
    required String curve,
    required String password,
  });

  /// Save wallet credentials to local storage
  Future<Either<Failure, void>> saveCredentials(WalletCreateModel credentials);

  /// Get saved wallet credentials
  Future<Either<Failure, WalletCredentials?>> getWalletCredentials();

  /// Delete wallet locally
  Future<Either<Failure, void>> deleteWallet();
}
