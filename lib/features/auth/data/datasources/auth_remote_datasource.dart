import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/error_codes.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_credentials_model.dart';

/// Email template types
enum EmailTemplate {
  verify,
  changepassword,
  initpassword,
}

/// OAuth2 grant types
enum GrantType {
  password,
  refreshToken('refresh_token');

  final String value;
  const GrantType([String? value]) : value = value ?? '';

  @override
  String toString() => value.isNotEmpty ? value : name;
}

abstract class AuthRemoteDataSource {
  Future<AuthCredentialsModel> loginWithEmail({
    required String email,
    required String encryptedPassword,
    required String secureChannelId,
  });

  Future<AuthCredentialsModel> loginWithSnsToken({
    required String snsToken,
    required String snsType,
  });

  Future<AuthCredentialsModel> refreshToken({
    required String refreshToken,
  });

  Future<bool> checkEmailAvailable({required String email});

  Future<void> sendVerificationCode({
    required String email,
    required EmailTemplate template,
  });

  Future<void> verifyCode({
    required String email,
    required String code,
  });

  Future<void> initPassword({
    required String email,
    required String encryptedPassword,
    required String secureChannelId,
    required String code,
  });

  Future<void> registerWithEmail({
    required String email,
    required String encryptedPassword,
    required String secureChannelId,
    required String code,
    required bool overage,
    required bool agree,
    required bool collect,
    required bool thirdparty,
    required bool advertise,
  });

  Future<void> registerWithSns({
    required String email,
    required String code,
    required String snsType,
    required bool overage,
    required bool agree,
    required bool collect,
    required bool thirdparty,
    required bool advertise,
  });
}

/// Auth remote data source implementation
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  String get _basicAuth {
    final credentials =
        '${AppConstants.clientId}:${AppConstants.clientSecret}';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  @override
  Future<AuthCredentialsModel> loginWithEmail({
    required String email,
    required String encryptedPassword,
    required String secureChannelId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'grant_type': GrantType.password.toString(),
          'username': email,
          'password': encryptedPassword,
          'audience': AppConstants.tokenAudience,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Authorization': _basicAuth,
            'User-Agent': AppConstants.userAgentPlatform,
            'Secure-Channel': secureChannelId,
          },
          extra: {'skipAuth': true},
        ),
      );

      return AuthCredentialsModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['code'] == ExpectedAPIErrorCode.userNotAuthorized) {
        throw AuthException(
          message: 'User not registered',
          code: ExpectedAPIErrorCode.userNotAuthorized,
        );
      }

      throw ServerException(
        message: _extractErrorMessage(data, 'Login failed'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AuthCredentialsModel> loginWithSnsToken({
    required String snsToken,
    required String snsType,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.snsTokenLogin,
        data: {
          'token': snsToken,
          'service': snsType,
          'audience': AppConstants.tokenAudience,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': _basicAuth},
          extra: {'skipAuth': true},
        ),
      );

      return AuthCredentialsModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['code'] == 618) {
        final msgData = data['msg'];
        final Map<String, dynamic> registrationInfo;

        if (msgData is String) {
          registrationInfo = json.decode(msgData) as Map<String, dynamic>;
        } else if (msgData is Map) {
          registrationInfo = Map<String, dynamic>.from(msgData);
        } else {
          registrationInfo = {};
        }

        throw AuthException(
          message: 'User not registered',
          code: ExpectedAPIErrorCode.notRegistered,
          data: registrationInfo,
        );
      }

      throw ServerException(
        message: data?['msg'] ?? 'SNS login failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AuthCredentialsModel> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        data: {
          'grant_type': GrantType.refreshToken.toString(),
          'refresh_token': refreshToken,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': _basicAuth},
          extra: {'skipAuth': true},
        ),
      );

      return AuthCredentialsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['msg'] ?? 'Token refresh failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<bool> checkEmailAvailable({required String email}) async {
    try {
      await _apiClient.get(
        ApiEndpoints.users(email),
        queryParameters: {'serviceid': AppConstants.tokenAudience},
        options: Options(
          headers: {'Authorization': _basicAuth},
          extra: {'skipAuth': true},
        ),
      );
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['code'] == ExpectedAPIErrorCode.emailAlreadyInUse) {
        return false;
      }
      throw ServerException(
        message: data?['msg'] ?? 'Email check failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> sendVerificationCode({
    required String email,
    required EmailTemplate template,
  }) async {
    final lang = PlatformDispatcher.instance.locale.languageCode;
    try {
      await _apiClient.get(
        ApiEndpoints.sendCode(email),
        queryParameters: {
          'lang': lang,
          'template': template.name,
        },
        options: Options(extra: {'skipAuth': true}),
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['msg'] ?? 'Failed to send code',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.verifyCode(email),
        data: {'code': code},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          extra: {'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['msg'] ?? 'Invalid code',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> initPassword({
    required String email,
    required String encryptedPassword,
    required String secureChannelId,
    required String code,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.initPassword,
        data: {
          'username': email,
          'password': encryptedPassword,
          'code': code,
          'serviceid': AppConstants.tokenAudience,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Authorization': _basicAuth,
            'Secure-Channel': secureChannelId,
          },
          extra: {'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['msg'] ?? 'Failed to initialize password',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String encryptedPassword,
    required String secureChannelId,
    required String code,
    required bool overage,
    required bool agree,
    required bool collect,
    required bool thirdparty,
    required bool advertise,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.emailAddUser,
        data: {
          'username': email,
          'password': encryptedPassword,
          'code': code,
          'serviceid': AppConstants.tokenAudience,
          'overage': overage ? 1 : 0,
          'agree': agree ? 1 : 0,
          'collect': collect ? 1 : 0,
          'thirdparty': thirdparty ? 1 : 0,
          'advertise': advertise ? 1 : 0,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Authorization': _basicAuth,
            'Secure-Channel': secureChannelId,
          },
          extra: {'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['code'] == ExpectedAPIErrorCode.emailAlreadyInUse) {
        throw AuthException(
          message: 'Email already in use',
          code: ExpectedAPIErrorCode.emailAlreadyInUse,
        );
      }
      throw ServerException(
        message: data?['msg'] ?? 'Registration failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> registerWithSns({
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
      await _apiClient.post(
        ApiEndpoints.snsJoin,
        data: {
          'username': email,
          'code': code,
          'serviceid': AppConstants.tokenAudience,
          'socialtype': snsType,
          'overage': overage ? 1 : 0,
          'agree': agree ? 1 : 0,
          'collect': collect ? 1 : 0,
          'thirdparty': thirdparty ? 1 : 0,
          'advertise': advertise ? 1 : 0,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': _basicAuth},
          extra: {'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['code'] == ExpectedAPIErrorCode.emailAlreadyInUse) {
        throw AuthException(
          message: 'Email already in use',
          code: ExpectedAPIErrorCode.emailAlreadyInUse,
        );
      }

      throw ServerException(
        message: data?['msg'] ?? 'Registration failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _extractErrorMessage(dynamic data, String defaultMessage) {
    if (data is Map) {
      return data['msg'] ?? data['error'] ?? data['message'] ?? defaultMessage;
    }
    return defaultMessage;
  }
}
