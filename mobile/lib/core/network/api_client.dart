import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'api_endpoints.dart';

class ApiClient {
  late final Dio dio;
  String? _authToken;

  ApiClient({String baseUrl = ApiEndpoints.baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-Request-ID'] = const Uuid().v4();
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          handler.next(options);
        },
        onError: (DioException err, handler) {
          // Log or format standard problem details
          handler.next(err);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;
}
