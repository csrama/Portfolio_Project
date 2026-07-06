import 'package:dio/dio.dart';
import 'dio_interceptor.dart';

class DioClient {
  static final Dio _instance = Dio(
    BaseOptions(
      baseUrl: 'https://your-api.onrender.com', 
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(AuthInterceptor());

  static Dio get instance => _instance;
}
