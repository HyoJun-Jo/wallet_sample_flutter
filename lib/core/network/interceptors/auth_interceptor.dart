import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import '../../auth/auth_session_manager.dart';
import '../../constants/api_endpoints.dart';
import '../../constants/app_constants.dart';
import '../../storage/secure_storage.dart';

/// Authentication interceptor - automatically attaches JWT token and handles refresh
class AuthInterceptor extends QueuedInterceptorsWrapper {
  final SecureStorageService _secureStorage;
  final AuthSessionManager _sessionManager;

  /// Separate Dio instance for refresh requests (avoids interceptor loop)
  Dio? _refreshDio;

  /// Flag to prevent multiple simultaneous refresh attempts
  bool _isRefreshing = false;

  AuthInterceptor({
    required SecureStorageService secureStorage,
    required AuthSessionManager sessionManager,
  })  : _secureStorage = secureStorage,
        _sessionManager = sessionManager;

  /// Create Basic Auth header from AppConstants
  String get _basicAuth {
    final credentials =
        '${AppConstants.clientId}:${AppConstants.clientSecret}';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  /// Get or create refresh Dio instance
  Dio get _getRefreshDio {
    _refreshDio ??= Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    return _refreshDio!;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check skipAuth flag (default: false - most APIs need auth)
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }

    // Attach JWT token
    final accessToken = await _secureStorage.read(
      key: SecureStorageKeys.accessToken,
    );

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Attach Secure Channel ID
    final secureChannelId = await _secureStorage.read(
      key: SecureStorageKeys.secureChannelId,
    );

    if (secureChannelId != null && secureChannelId.isNotEmpty) {
      options.headers['Secure-Channel'] = secureChannelId;
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Skip if skipAuth is true
    if (err.requestOptions.extra['skipAuth'] == true) {
      handler.next(err);
      return;
    }

    // Handle token expiration: 401 OR (403 + JWT_EXPIRED)
    final isExpired = _isTokenExpiredError(err);
    if (!isExpired) {
      handler.next(err);
      return;
    }

    // Try to refresh token
    final refreshed = await _tryRefreshToken();
    if (refreshed) {
      // Retry original request with new token
      try {
        final newAccessToken = await _secureStorage.read(
          key: SecureStorageKeys.accessToken,
        );

        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newAccessToken';

        // Use a new Dio instance to retry (avoid loop)
        final response = await _getRefreshDio.fetch(options);
        handler.resolve(response);
        return;
      } catch (retryError) {
        // Retry failed, pass original error
        handler.next(err);
        return;
      }
    }

    // Refresh failed, pass original error
    handler.next(err);
  }

  /// Check if the error is an authentication error (401 or 403)
  bool _isTokenExpiredError(DioException err) {
    final statusCode = err.response?.statusCode;

    // 401 Unauthorized or 403 Forbidden - both are auth errors, try refresh
    if (statusCode == 401 || statusCode == 403) {
      return true;
    }

    return false;
  }

  /// Try to refresh the access token
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) {
      // Another refresh is in progress, wait for it
      await Future.delayed(const Duration(milliseconds: 100));
      final token = await _secureStorage.read(key: SecureStorageKeys.accessToken);
      return token != null && token.isNotEmpty;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.read(
        key: SecureStorageKeys.refreshToken,
      );

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _getRefreshDio.post(
        ApiEndpoints.refreshToken,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Authorization': _basicAuth,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken != null) {
          await _secureStorage.write(
            key: SecureStorageKeys.accessToken,
            value: newAccessToken,
          );
        }

        if (newRefreshToken != null) {
          await _secureStorage.write(
            key: SecureStorageKeys.refreshToken,
            value: newRefreshToken,
          );
        }

        return true;
      }

      return false;
    } catch (e) {
      developer.log('Token refresh failed: $e', name: 'AuthInterceptor');
      // Refresh failed, clear tokens and notify session expired
      await _secureStorage.delete(key: SecureStorageKeys.accessToken);
      await _secureStorage.delete(key: SecureStorageKeys.refreshToken);
      _sessionManager.onSessionExpired();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}
