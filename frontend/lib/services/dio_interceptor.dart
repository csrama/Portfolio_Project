import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await _authService.refreshAccessToken();
        if (newToken != null) {
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await Dio().fetch(requestOptions);
          return handler.resolve(response);
        }
      } catch (e) {
        await _authService.clearTokens();
      }
    }
    return handler.next(err);
  }
}
