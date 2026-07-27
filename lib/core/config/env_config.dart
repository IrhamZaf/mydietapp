import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvConfig {
  static const String productionBaseUrl =
      'https://mydiet.vinculotech.com/api/v1';

  /// Base URL for API requests.
  /// Override at build time via:
  /// flutter build ipa --release --dart-define=BASE_URL=https://mydiet.vinculotech.com/api/v1
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('BASE_URL');
    if (definedUrl.isNotEmpty) {
      return definedUrl;
    }

    // Release/TestFlight builds always hit production unless overridden.
    if (kReleaseMode) {
      return productionBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }

    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api/v1';
      }
      if (Platform.isIOS) {
        return 'http://127.0.0.1:8000/api/v1';
      }
    } catch (_) {}

    return 'http://127.0.0.1:8000/api/v1';
  }

  /// Whether the app is running in Production mode
  static bool get isProduction => kReleaseMode;
}
