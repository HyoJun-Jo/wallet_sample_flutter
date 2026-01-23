import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/transaction_entities.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _remoteDataSource;

  TransactionRepositoryImpl({
    required TransactionRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

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
