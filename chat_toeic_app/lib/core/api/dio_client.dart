import 'package:dio/dio.dart';
import 'package:chat_toeic_app/core/api/auth_interceptor.dart';
import 'package:chat_toeic_app/core/utils/app_env.dart';
import 'package:logger/logger.dart';

class DioClient {
  static late Dio dio;
  static final logger = Logger();

  static void init() {
    dio = Dio(BaseOptions(
      baseUrl: AppEnv.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));

    dio.interceptors.add(AuthInterceptor(dio));
    
    // Log interceptor for debugging
    // dio.interceptors.add(LogInterceptor(
    //   requestBody: true,
    //   responseBody: true,
    //   logPrint: (o) => logger.i(o),
    // ));
  }
}
