import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../features/wallet/data/models/wallet_model.dart';
import '../../domain/entities/transaction_entities.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;

  TransactionRepositoryImpl({
    required TransactionRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage;

  /// Get saved wallet credentials
  Future<WalletCreateResultModel> _getCredentials() async {
    final jsonString = await _secureStorage.read(
      key: SecureStorageKeys.walletCredentials,
    );
    final credentials = WalletCreateResultModel.fromJsonString(jsonString);
    if (credentials == null) {
      throw ServerException(message: 'Wallet credentials not found');
    }
    return credentials;
  }

  @override
  Future<Either<Failure, String>> getNonce({
    required String address,
    required String network,
  }) async {
    try {
      final nonce = await _remoteDataSource.getNonce(
        address: address,
        network: network,
      );
      return Right(nonce);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, GasFees>> getGasFees({
    required String network,
  }) async {
    try {
      final gasFees = await _remoteDataSource.getGasFees(network: network);
      return Right(gasFees);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EstimateGasResult>> estimateGas({
    required EstimateGasParams params,
  }) async {
    try {
      final gasLimit = await _remoteDataSource.estimateGas(params: params);
      return Right(EstimateGasResult(gasLimit: gasLimit));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignedTransaction>> signTransaction({
    required SignTransactionParams params,
  }) async {
    try {
      final credentials = await _getCredentials();
      final result = await _remoteDataSource.signTransaction(
        params: params,
        credentials: credentials,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionResult>> sendTransaction({
    required SendTransactionParams params,
  }) async {
    try {
      final txHash = await _remoteDataSource.sendTransaction(params: params);
      return Right(TransactionResult(txHash: txHash));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
