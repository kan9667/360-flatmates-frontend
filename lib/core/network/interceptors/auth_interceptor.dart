import 'package:dio/dio.dart';

import '../auth_token_provider.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required AuthTokenProvider tokenProvider,
    required Dio dio,
  })  : _tokenProvider = tokenProvider,
        _dio = dio;

  final AuthTokenProvider _tokenProvider;
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenProvider.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final newToken = await _tokenProvider.getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(opts);
          _isRefreshing = false;
          handler.resolve(response);
          return;
        }
        _isRefreshing = false;
      } catch (_) {
        _isRefreshing = false;
      }
      await _tokenProvider.clearSession();
    }
    handler.next(err);
  }
}
