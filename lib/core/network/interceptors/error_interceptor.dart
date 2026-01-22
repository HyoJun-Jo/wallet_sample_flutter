import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';

/// Error interceptor - handles server response errors
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    // Timeout errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: NetworkException(message: 'Connection timeout'),
        type: err.type,
      ));
      return;
    }

    // Connection errors
    if (err.type == DioExceptionType.connectionError) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: NetworkException(message: 'No internet connection'),
        type: err.type,
      ));
      return;
    }

    // Response errors
    if (response != null) {
      final statusCode = response.statusCode;
      final data = response.data;

      String message = _extractErrorMessage(data, err);
      int? errorCode = _extractErrorCode(data);

      // Authentication-related errors
      if (statusCode == 401 || statusCode == 403) {
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          response: response,
          error: AuthException(message: message, code: errorCode),
          type: err.type,
        ));
        return;
      }

      // Other server errors
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        response: response,
        error: ServerException(message: message, statusCode: statusCode),
        type: err.type,
      ));
      return;
    }

    // Unknown errors - pass the original error message
    final errorMessage = err.message ?? err.error?.toString() ?? 'Unknown error';
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: ServerException(message: errorMessage, statusCode: null),
      type: err.type,
    ));
  }

  String _extractErrorMessage(dynamic data, DioException err) {
    if (data == null) {
      return err.message ?? err.error?.toString() ?? 'Unknown error';
    }

    if (data is Map<String, dynamic>) {
      // Try various common error message fields
      return data['msg'] as String? ??
          data['message'] as String? ??
          data['error'] as String? ??
          data['error_description'] as String? ??
          (data['errors'] is List ? (data['errors'] as List).join(', ') : null) ??
          data.toString();
    }

    if (data is String) {
      return data;
    }

    return data.toString();
  }

  int? _extractErrorCode(dynamic data) {
    if (data is Map<String, dynamic>) {
      final code = data['code'] ?? data['error_code'] ?? data['errorCode'];
      if (code is int) return code;
      if (code is String) return int.tryParse(code);
    }
    return null;
  }
}
