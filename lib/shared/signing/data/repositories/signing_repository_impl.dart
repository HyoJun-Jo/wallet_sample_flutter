import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../wallet/data/datasources/wallet_local_datasource.dart';
import '../../../wallet/data/models/wallet_create_model.dart';
import '../../domain/entities/signing_entities.dart';
import '../../domain/repositories/signing_repository.dart';
import '../datasources/signing_remote_datasource.dart';

/// Signing Repository implementation
class SigningRepositoryImpl implements SigningRepository {
  final SigningRemoteDataSource _remoteDataSource;
  final WalletLocalDataSource _walletLocalDataSource;

  SigningRepositoryImpl({
    required SigningRemoteDataSource remoteDataSource,
    required WalletLocalDataSource walletLocalDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _walletLocalDataSource = walletLocalDataSource;

  /// Get saved wallet credentials
  Future<WalletCreateModel> _getCredentials() async {
    final credentials = await _walletLocalDataSource.getCredentials();
    if (credentials == null) {
      throw SigningException(message: 'Wallet credentials not found');
    }
    return credentials;
  }

  @override
  Future<Either<Failure, PersonalSignResult>> personalSign({
    required PersonalSignParams params,
  }) async {
    try {
      final credentials = await _getCredentials();
      final result = await _remoteDataSource.personalSign(
        params: params,
        credentials: credentials,
      );
      return Right(result.toPersonalSignResult());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on SigningException catch (e) {
      return Left(SigningFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignTypedDataResult>> signTypedData({
    required SignTypedDataParams params,
  }) async {
    try {
      final credentials = await _getCredentials();
      final result = await _remoteDataSource.signTypedData(
        params: params,
        credentials: credentials,
      );
      return Right(result.toSignTypedDataResult());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on SigningException catch (e) {
      return Left(SigningFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignHashResult>> signHash({
    required SignHashParams params,
  }) async {
    try {
      final credentials = await _getCredentials();
      final result = await _remoteDataSource.signHash(
        params: params,
        credentials: credentials,
      );
      return Right(result.toSignHashResult());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on SigningException catch (e) {
      return Left(SigningFailure(message: e.message));
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
      return Right(result.toSignedTransaction());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on SigningException catch (e) {
      return Left(SigningFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
