import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../wallet/data/models/wallet_model.dart';
import '../../domain/entities/sign_request.dart';
import '../../domain/repositories/signing_repository.dart';
import '../datasources/signing_remote_datasource.dart';

/// Signing Repository implementation
class SigningRepositoryImpl implements SigningRepository {
  final SigningRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;

  SigningRepositoryImpl({
    required SigningRemoteDataSource remoteDataSource,
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
      throw SigningException(message: 'Wallet credentials not found');
    }
    return credentials;
  }

  @override
  Future<Either<Failure, SignResult>> sign({
    required SignRequest request,
  }) async {
    try {
      final credentials = await _getCredentials();
      final result = await _remoteDataSource.sign(
        request: request,
        credentials: credentials,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on SigningException catch (e) {
      return Left(SigningFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignResult>> signTypedData({
    required TypedDataSignRequest request,
  }) async {
    try {
      final credentials = await _getCredentials();
      final result = await _remoteDataSource.signTypedData(
        request: request,
        credentials: credentials,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on SigningException catch (e) {
      return Left(SigningFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignResult>> signHash({
    required HashSignRequest request,
  }) async {
    try {
      final credentials = await _getCredentials();
      final result = await _remoteDataSource.signHash(
        request: request,
        credentials: credentials,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on SigningException catch (e) {
      return Left(SigningFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignResult>> signEip1559({
    required Eip1559SignRequest request,
  }) async {
    try {
      final credentials = await _getCredentials();
      final result = await _remoteDataSource.signEip1559(
        request: request,
        credentials: credentials,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on SigningException catch (e) {
      return Left(SigningFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
