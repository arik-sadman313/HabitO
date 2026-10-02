import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/secure_session_manager.dart';
import '../config/app_config.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(SecureSessionManager());
});

class DioClient {
  late final Dio _dio;
  final SecureSessionManager _sessionManager;

  DioClient(this._sessionManager) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _sessionManager.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Attempt token refresh
          final refreshToken = await _sessionManager.getRefreshToken();
          if (refreshToken != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
              final response = await refreshDio.post('/auth/refresh', data: {
                'refresh_token': refreshToken,
              });

              final newAccessToken = response.data['access_token'];
              final newRefreshToken = response.data['refresh_token'];

              await _sessionManager.saveTokens(access: newAccessToken, refresh: newRefreshToken);

              // Retry original request
              error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final cloneReq = await _dio.fetch(error.requestOptions);
              return handler.resolve(cloneReq);
            } catch (e) {
              await _sessionManager.clearSession();
              // Pass the error down to force logout
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}
