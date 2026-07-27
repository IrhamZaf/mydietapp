import 'package:dio/dio.dart';
import 'package:my_diet_app/core/config/env_config.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/core/storage/secure_storage_service.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService _storageService;

  ApiClient(this._storageService) {
    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storageService.deleteToken();
          }

          final message = _extractErrorMessage(error);
          final apiException = ApiException(
            message: message,
            statusCode: error.response?.statusCode,
            errors: error.response?.data is Map ? (error.response?.data['errors'] as Map<String, dynamic>?) : null,
          );

          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: apiException,
            ),
          );
        },
      ),
    );
  }

  String _extractErrorMessage(DioException error) {
    if (error.response?.data is Map) {
      final data = error.response!.data as Map;
      if (data.containsKey('message') && data['message'] != null) {
        return data['message'].toString();
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Network connection timed out. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to backend server at ${EnvConfig.baseUrl}. Is the server running?';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
