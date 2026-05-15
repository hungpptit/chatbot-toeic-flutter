import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static String get baseUrl => _resolveUrl(
        envKey: 'BASE_URL',
        webFallback: 'http://localhost:8080/api',
        nativeFallback: 'http://10.0.2.2:8080/api',
      );

  static String get swaggerJsonUrl => _resolveUrl(
        envKey: 'SWAGGER_JSON_URL',
        webFallback: 'http://localhost:8080/api/docs-json',
        nativeFallback: 'http://10.0.2.2:8080/api/docs-json',
      );

  static String _resolveUrl({
    required String envKey,
    required String webFallback,
    required String nativeFallback,
  }) {
    final configured = dotenv.env[envKey]?.trim();
    final fallback = kIsWeb ? webFallback : nativeFallback;
    final url = (configured == null || configured.isEmpty) ? fallback : configured;

    if (kIsWeb) {
      return url;
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null) {
      return url;
    }

    if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
      return parsed.replace(host: '10.0.2.2').toString();
    }

    return url;
  }
  
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }
}
