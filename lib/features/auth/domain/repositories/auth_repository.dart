import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_entities.dart';

/// Authentication Repository interface
abstract class AuthRepository {
  /// Email login
  /// Returns EmailLoginResult: EmailLoginSuccess or EmailUserNotRegistered
  Future<Either<Failure, EmailLoginResult>> loginWithEmail({
    required String email,
    required String password,
  });

  /// SNS token login
  /// Returns SnsLoginResult: SnsLoginSuccess or SnsUserNotFound
  Future<Either<Failure, SnsLoginResult>> loginWithSnsToken({
    required String snsToken,
    required String snsType,
  });

  /// Register with SNS (after code 618 - user not found)
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

  /// Refresh token
  Future<Either<Failure, AuthCredentials>> refreshToken({
    required String refreshToken,
  });

  /// Logout
  Future<Either<Failure, void>> logout();

  /// Get saved credentials
  Future<Either<Failure, AuthCredentials?>> getSavedCredentials();

  /// Save credentials
  Future<Either<Failure, void>> saveCredentials(AuthCredentials credentials);

  /// Check if email is available for registration
  Future<Either<Failure, bool>> checkEmailAvailable({required String email});

  /// Send verification code to email
  Future<Either<Failure, void>> sendVerificationCode({
    required String email,
    required String template,
  });

  /// Verify email code
  Future<Either<Failure, void>> verifyCode({
    required String email,
    required String code,
  });

  /// Initialize password for email registration
  Future<Either<Failure, void>> initPassword({
    required String email,
    required String password,
    required String code,
  });

  /// Register with email and password
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

  /// Save user session (email and login type)
  Future<Either<Failure, void>> saveUserSession({
    required String email,
    required LoginType loginType,
  });

  /// Get user session (email and login type)
  Future<Either<Failure, (String?, LoginType?)>> getUserSession();

  /// Clear user session
  Future<Either<Failure, void>> clearUserSession();
}
