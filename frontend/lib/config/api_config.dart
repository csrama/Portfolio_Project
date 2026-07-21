import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Base URL of the backend API.
  /// On web we can reach localhost directly; on Android emulator we use 10.0.2.2.
  static String get baseUrl {
    if (kIsWeb) {
      return 'const String baseUrl = 'https://portfolioproject-production-2b3b.up.railway.app';';
    }
    return 'http://10.0.2.2:3000';
  }
}
