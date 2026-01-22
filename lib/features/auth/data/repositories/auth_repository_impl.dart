import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import '../../../../core/constants/error_codes.dart';
import '../../../../core/crypto/secure_channel_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_credentials_model.dart';

/// Auth Repository implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;
  final SecureChannelService _secureChannelService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
    required LocalStorageService localStorage,
    required SecureChannelService secureChannelService,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage,
        _localStorage = localStorage,
        _secureChannelService = secureChannelService;

  @override
  Future<Either<Failure, EmailLoginResult>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      developer.log('Auth: loginWithEmail for $email', name: 'Auth');

      final channel = await _secureChannelService.getOrCreateChannel();
      final encryptedPassword = _secureChannelService.encryptWithChannel(
        password,
        channel,
      );

      final result = await _remoteDataSource.loginWithEmail(
        email: email,
        encryptedPassword: encryptedPassword,
        secureChannelId: channel.channelId,
      );

      await _saveCredentialsToStorage(result);
      developer.log('Auth: Login successful', name: 'Auth');

      return Right(EmailLoginSuccess(credentials: result));
    } on ServerException catch (e) {
      developer.log('Auth: Login failed - ${e.message}', name: 'Auth');
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on AuthException catch (e) {
      // User not registered (code 602) - return sealed class for branching
      if (e.code == ExpectedAPIErrorCode.userNotAuthorized) {
        return Right(EmailUserNotRegistered(email: email));
      }
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      developer.log('Auth: Unexpected error - $e', name: 'Auth');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SnsLoginResult>> loginWithSnsToken({
    required String snsToken,
    required String snsType,
  }) async {
    try {
      final result = await _remoteDataSource.loginWithSnsToken(
        snsToken: snsToken,
        snsType: snsType,
      );

      await _saveCredentialsToStorage(result);
      return Right(SnsLoginSuccess(credentials: result));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on AuthException catch (e) {
      // User not registered (code 618) - return sealed class for branching
      if (e.code == ExpectedAPIErrorCode.notRegistered && e.data != null) {
        return Right(SnsUserNotFound(
          email: e.data!['email'] ?? '',
          token: e.data!['token'] ?? '',
          sixcode: e.data!['sixcode'] ?? '',
          language: e.data!['language'] ?? 'en',
          timeout: e.data!['timeout'] ?? 3600,
        ));
      }
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthCredentials>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final result = await _remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );

      await _saveCredentialsToStorage(result);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _secureStorage.delete(key: SecureStorageKeys.accessToken);
      await _secureStorage.delete(key: SecureStorageKeys.refreshToken);
      await _localStorage.remove(LocalStorageKeys.userEmail);
      await _localStorage.remove(LocalStorageKeys.loginType);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthCredentials?>> getSavedCredentials() async {
    try {
      final accessToken = await _secureStorage.read(
        key: SecureStorageKeys.accessToken,
      );
      final refreshToken = await _secureStorage.read(
        key: SecureStorageKeys.refreshToken,
      );

      if (accessToken == null || refreshToken == null) {
        return const Right(null);
      }

      return Right(AuthCredentialsModel(
        accessToken: accessToken,
        tokenType: 'bearer',
        expiresIn: 0,
        refreshToken: refreshToken,
      ));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCredentials(AuthCredentials credentials) async {
    try {
      await _saveCredentialsToStorage(credentials);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  Future<void> _saveCredentialsToStorage(AuthCredentials credentials) async {
    await _secureStorage.write(
      key: SecureStorageKeys.accessToken,
      value: credentials.accessToken,
    );
    await _secureStorage.write(
      key: SecureStorageKeys.refreshToken,
      value: credentials.refreshToken,
    );
  }

  @override
  Future<Either<Failure, void>> registerWithSns({
    required String email,
    required String code,
    required String snsType,
    required bool overage,
    required bool agree,
    required bool collect,
    required bool thirdparty,
    required bool advertise,
  }) async {
    try {
      await _remoteDataSource.registerWithSns(
        email: email,
        code: code,
        snsType: snsType,
        overage: overage,
        agree: agree,
        collect: collect,
        thirdparty: thirdparty,
        advertise: advertise,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailAvailable({
    required String email,
  }) async {
    try {
      final result = await _remoteDataSource.checkEmailAvailable(email: email);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendVerificationCode({
    required String email,
    required String template,
  }) async {
    try {
      final emailTemplate = EmailTemplate.values.firstWhere(
        (e) => e.name == template,
        orElse: () => EmailTemplate.verify,
      );
      await _remoteDataSource.sendVerificationCode(
        email: email,
        template: emailTemplate,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      await _remoteDataSource.verifyCode(email: email, code: code);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> initPassword({
    required String email,
    required String password,
    required String code,
  }) async {
    try {
      final channel = await _secureChannelService.getOrCreateChannel();
      final encryptedPassword = _secureChannelService.encryptWithChannel(
        password,
        channel,
      );

      await _remoteDataSource.initPassword(
        email: email,
        encryptedPassword: encryptedPassword,
        secureChannelId: channel.channelId,
        code: code,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerWithEmail({
    required String email,
    required String password,
    required String code,
    required bool overage,
    required bool agree,
    required bool collect,
    required bool thirdparty,
    required bool advertise,
  }) async {
    try {
      final channel = await _secureChannelService.getOrCreateChannel();
      final encryptedPassword = _secureChannelService.encryptWithChannel(
        password,
        channel,
      );

      await _remoteDataSource.registerWithEmail(
        email: email,
        encryptedPassword: encryptedPassword,
        secureChannelId: channel.channelId,
        code: code,
        overage: overage,
        agree: agree,
        collect: collect,
        thirdparty: thirdparty,
        advertise: advertise,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveUserSession({
    required String email,
    required LoginType loginType,
  }) async {
    try {
      await _localStorage.setString(LocalStorageKeys.userEmail, email);
      await _localStorage.setString(LocalStorageKeys.loginType, loginType.name);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, (String?, LoginType?)>> getUserSession() async {
    try {
      final email = _localStorage.getString(LocalStorageKeys.userEmail);
      final typeStr = _localStorage.getString(LocalStorageKeys.loginType);
      final loginType = typeStr != null
          ? LoginType.values.firstWhere(
              (e) => e.name == typeStr,
              orElse: () => LoginType.email,
            )
          : null;
      return Right((email, loginType));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearUserSession() async {
    try {
      await _localStorage.remove(LocalStorageKeys.userEmail);
      await _localStorage.remove(LocalStorageKeys.loginType);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
