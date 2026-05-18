import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

    // If running on web, never use ngrok; always use the local web URL.
    if (kIsWeb) {
      return webFallback;
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null) {
      return url;
    }

    // If configured URL points to localhost, replace with emulator host.
    if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
      return parsed.replace(host: '10.0.2.2').toString();
    }

    // If configured URL is an ngrok/public tunnel, only use it on a physical device.
    final isNgrok = parsed.host.contains('ngrok') || parsed.host.contains('ngrok-free.dev');
    if (isNgrok) {
      final isPhysical = _isPhysicalDevice ?? true;
      if (!isPhysical) {
        // emulator or unknown -> fall back to local emulator/web host
        return fallback;
      }
    }

    return url;
  }
  
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
    // Detect whether running on a physical device (used to decide ngrok usage)
    try {
      if (!kIsWeb) {
        final deviceInfo = DeviceInfoPlugin();
        if (defaultTargetPlatform == TargetPlatform.android) {
          final info = await deviceInfo.androidInfo;
          _isPhysicalDevice = info.isPhysicalDevice;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final info = await deviceInfo.iosInfo;
          _isPhysicalDevice = info.isPhysicalDevice;
        } else {
          _isPhysicalDevice = true;
        }
      } else {
        _isPhysicalDevice = true;
      }
    } catch (_) {
      _isPhysicalDevice = true;
    }
  }

  static bool? _isPhysicalDevice;
}
