import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(ErrorInterceptor());

  return dio;
});

class AuthInterceptor extends Interceptor {
  String? _token;

  AuthInterceptor(Ref ref);

  void updateToken(String? token) {
    _token = token;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_token != null && _token!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_token';
    }
    handler.next(options);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _extractErrorMessage(err);
    final errors = _extractErrors(err);
    handler.next(DioException(
      type: err.type,
      requestOptions: err.requestOptions,
      response: err.response,
      message: message,
      error: errors,
    ));
  }

  String _extractErrorMessage(DioException err) {
    try {
      final data = err.response?.data;
      if (data is Map) return data['message'] ?? 'An unexpected error occurred';
      return 'An unexpected error occurred';
    } catch (_) {
      return 'An unexpected error occurred';
    }
  }

  Map<String, dynamic>? _extractErrors(DioException err) {
    try {
      final data = err.response?.data;
      if (data is! Map) return null;
      return data['errors'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
