import 'package:dartz/dartz.dart';

import '../../errors/failures.dart';
import '../entities/auth_entities.dart';

abstract class AuthRepository {
  /// Returns [EmailLoginSuccess] or [EmailUserNotRegistered]
  Future<Either<Failure, EmailLoginResult>> loginWithEmail({
    required String email,
    required String password,
  });

  /// Returns [SnsLoginSuccess] or [SnsUserNotFound]
  Future<Either<Failure, SnsLoginResult>> loginWithSnsToken({
    required String snsToken,
    required String snsType,
  });

  Future<Either<Failure, AuthCredentials>> refreshToken({
    required String refreshToken,
  });

  Future<Either<Failure, AuthCredentials?>> getSavedCredentials();

  Future<Either<Failure, bool>> checkEmailAvailable({required String email});

  Future<Either<Failure, void>> sendVerificationCode({
    required String email,
    required String template,
  });

  Future<Either<Failure, void>> verifyCode({
    required String email,
    required String code,
  });

  Future<Either<Failure, void>> initPassword({
    required String email,
    required String password,
    required String code,
  });

  Future<Either<Failure, void>> registerWithEmail({
    required String email,
    required String password,
    required String code,
    required bool overage,
    required bool agree,
    required bool collect,
    required bool thirdparty,
    required bool advertise,
  });

  Future<Either<Failure, void>> registerWithSns({
    required String email,
    required String code,
    required String snsType,
    required bool overage,
    required bool agree,
    required bool collect,
    required bool thirdparty,
    required bool advertise,
  });

  Future<Either<Failure, void>> saveUserSession({
    required String email,
    required LoginType loginType,
  });
}
