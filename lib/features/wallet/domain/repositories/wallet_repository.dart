import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet.dart';

/// Wallet Repository interface
abstract class WalletRepository {
  /// Create and register wallet
  /// Creates EVM multi-chain wallet with encrypted PIN
  Future<Either<Failure, WalletCreateResult>> createWallet({
    required String email,
    required String password,
  });

  /// Get saved wallets list
  Future<Either<Failure, List<Wallet>>> getSavedWallets();

  /// Save KeyShare
  Future<Either<Failure, void>> saveKeyShare({
    required String address,
    required String keyShare,
  });

  /// Get KeyShare
  Future<Either<Failure, String?>> getKeyShare({
    required String address,
  });

  /// Delete wallet locally
  Future<Either<Failure, void>> deleteWallet({
    required String address,
  });

  /// Get saved wallet credentials
  Future<Either<Failure, WalletCredentials?>> getWalletCredentials();
}
