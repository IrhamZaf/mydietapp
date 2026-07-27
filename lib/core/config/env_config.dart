import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvConfig {
  /// Base URL for API requests.
  /// Can be overridden at build time via:
  /// flutter build apk --release --dart-define=BASE_URL=https://mydiet.vinculotech.com/api/v1
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('BASE_URL');
    if (definedUrl.isNotEmpty) {
      return definedUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }

    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api/v1';
      }
    } catch (_) {}

    return 'http://10.0.2.2:8000/api/v1';
  }

  /// Whether the app is running in Production mode
  static bool get isProduction => kReleaseMode;
}
