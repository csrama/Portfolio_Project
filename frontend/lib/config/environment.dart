import 'package:flutter/foundation.dart';

class Environment {
 
  static const String _webDevUrl = 'http://localhost:3000';
  static const String _mobileDevUrl = 'http://10.0.2.2:3000';
  static const String _prodUrl = 'https://api.your-app.com';
  static const String _stagingUrl = 'https://staging-api.your-app.com';

  

  static String get baseUrl {
    if (isProduction) return _prodUrl;
    if (isStaging) return _stagingUrl;
    
    if (kIsWeb) return _webDevUrl;
    return _mobileDevUrl;
  }

  
  static bool get isDevelopment {
    const bool debug = bool.fromEnvironment('DEBUG');
    return debug && !kReleaseMode;
  }

  static bool get isStaging {
    const bool staging = bool.fromEnvironment('STAGING');
    return staging;
  }

  static bool get isProduction {
    return kReleaseMode && !isStaging;
  }

  static String get currentEnvironment {
    if (isProduction) return 'Production';
    if (isStaging) return 'Staging';
    return 'Development';
  }


  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;

  static bool get isDebugMode {
    const bool debug = bool.fromEnvironment('DEBUG', defaultValue: true);
    return debug;
  }

  static bool get enableLogging => isDebugMode || isDevelopment;

  static const String appName = 'MedTrack';
  static const String version = '1.0.0';


  static String buildUrl(String path) {
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }

  static void printEnvironmentInfo() {
    print('========================================');
    print(' Environment: $currentEnvironment');
    print(' Platform: ${kIsWeb ? "Web" : "Mobile"}');
    print(' Base URL: $baseUrl');
    print(' Debug Mode: $isDebugMode');
    print(' Logging: $enableLogging');
    print(' Version: $version');
    print('========================================');
  }
}
