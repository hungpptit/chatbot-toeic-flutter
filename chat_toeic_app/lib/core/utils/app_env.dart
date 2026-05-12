import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://localhost:8080/api';
  static String get swaggerJsonUrl => dotenv.env['SWAGGER_JSON_URL'] ?? 'http://localhost:8080/api/docs-json';
  
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }
}
