import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet_credentials.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_datasource.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../models/wallet_create_model.dart';
import '../models/wallet_info_model.dart';
import '../models/wallet_v3_info_model.dart';

/// Wallet Repository implementation
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;
  final WalletLocalDataSource _localDataSource;

  WalletRepositoryImpl({
    required WalletRemoteDataSource remoteDataSource,
    required WalletLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<bool> checkWallet() => _localDataSource.hasCredentials();

  @override
  Future<Either<Failure, WalletCreateModel>> createWallet({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.createWallet(
        email: email,
        password: password,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on WalletException catch (e) {
      return Left(WalletFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletInfoModel>> getWalletInfo() async {
    try {
      final result = await _remoteDataSource.getWalletInfo();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on WalletException catch (e) {
      return Left(WalletFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> lookupBtcAddress({
    required String pubkey,
    required String network,
  }) async {
    try {
      final result = await _remoteDataSource.lookupBtcAddress(
        pubkey: pubkey,
        network: network,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on WalletException catch (e) {
      return Left(WalletFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletV3InfoModel>> getV3Wallet() async {
    try {
      final result = await _remoteDataSource.getV3Wallet();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on WalletException catch (e) {
      return Left(WalletFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ed25519KeyShareInfoModel>> generateV3Wallet({
    required String curve,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.generateV3Wallet(
        curve: curve,
        password: password,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on WalletException catch (e) {
      return Left(WalletFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ed25519KeyShareInfoModel>> recoverV3Wallet({
    required String curve,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.recoverV3Wallet(
        curve: curve,
        password: password,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on WalletException catch (e) {
      return Left(WalletFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCredentials(
      WalletCreateModel credentials) async {
    try {
      await _localDataSource.saveCredentials(credentials);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletCredentials?>> getWalletCredentials() async {
    try {
      final model = await _localDataSource.getCredentials();
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWallet() async {
    try {
      await _localDataSource.deleteCredentials();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
