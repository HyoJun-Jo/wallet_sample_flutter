import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/wallet_create_model.dart';
import '../entities/wallet_credentials.dart';
import '../repositories/wallet_repository.dart';

/// Create wallet UseCase - orchestrates multi-chain wallet creation
class CreateWalletUseCase
    implements UseCase<WalletCredentials, CreateWalletParams> {
  final WalletRepository _repository;

  CreateWalletUseCase(this._repository);

  @override
  Future<Either<Failure, WalletCredentials>> call(
      CreateWalletParams params) async {
    // 1. Create EVM wallet (required)
    final evmResult = await _repository.createWallet(
      email: params.email,
      password: params.password,
    );

    return evmResult.fold(
      (failure) => Left(failure),
      (evmWallet) async {
        var credentials = evmWallet;

        // 2. Get BTC address (optional)
        final btcAddress = await _getBtcAddress();
        if (btcAddress != null) {
          credentials = credentials.copyWith(btcAddress: btcAddress);
        }

        // 3. Activate Solana wallet (optional)
        final solResult = await _activateSolanaWallet(params.password);
        if (solResult != null) {
          credentials = credentials.copyWith(
            solAddress: solResult.$1,
            ed25519KeyShareInfo: solResult.$2,
          );
        }

        // 4. Save credentials
        final saveResult = await _repository.saveCredentials(credentials);
        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(credentials.toEntity()),
        );
      },
    );
  }

  /// Get BTC address from wallet's pubkey
  Future<String?> _getBtcAddress() async {
    try {
      final walletInfoResult = await _repository.getWalletInfo();
      return walletInfoResult.fold(
        (failure) {
          debugPrint('[CreateWallet] getWalletInfo failed: ${failure.message}');
          return null;
        },
        (walletInfo) async {
          final pubkey = walletInfo.primaryAccount?.pubkey;
          debugPrint('[CreateWallet] pubkey: $pubkey');
          if (pubkey == null) return null;

          final btcResult = await _repository.lookupBtcAddress(
            pubkey: pubkey,
            network: AppConstants.btcNetwork,
          );
          return btcResult.fold(
            (failure) {
              debugPrint('[CreateWallet] lookupBtcAddress failed: ${failure.message}');
              return null;
            },
            (address) {
              debugPrint('[CreateWallet] btcAddress: $address');
              return address;
            },
          );
        },
      );
    } catch (e) {
      debugPrint('[CreateWallet] _getBtcAddress error: $e');
      return null;
    }
  }

  /// Activate Solana wallet (generate or recover V3)
  Future<(String?, Ed25519KeyShareInfoModel?)?> _activateSolanaWallet(
      String password) async {
    try {
      const curve = 'ed25519';
      bool hasEd25519 = false;

      // 1. Check if V3 wallet exists
      final v3InfoResult = await _repository.getV3Wallet();
      v3InfoResult.fold(
        (_) {}, // V3_USER_NOT_FOUND - need to generate
        (v3Info) => hasEd25519 = v3Info.hasEd25519,
      );

      // 2. Generate or recover V3 wallet
      final keyShareResult = !hasEd25519
          ? await _repository.generateV3Wallet(curve: curve, password: password)
          : await _repository.recoverV3Wallet(curve: curve, password: password);

      return keyShareResult.fold(
        (_) => null,
        (keyShare) async {
          // 3. Query V3 wallet again to get Solana address
          final walletResult = await _repository.getV3Wallet();
          return walletResult.fold(
            (_) => (null, keyShare),
            (walletInfo) {
              final solAddress = walletInfo.findByCurve(curve)?.solanaAddress;
              return (solAddress, keyShare);
            },
          );
        },
      );
    } catch (_) {
      return null;
    }
  }
}

class CreateWalletParams extends Equatable {
  final String email;
  final String password;

  const CreateWalletParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}
