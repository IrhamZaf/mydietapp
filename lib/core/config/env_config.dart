import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvConfig {
  /// Base URL for API requests.
  /// Android Emulator accesses host localhost via http://10.0.2.2:8000/api/v1
  static String get baseUrl {
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
}
