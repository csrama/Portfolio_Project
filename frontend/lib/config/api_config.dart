import 'package:flutter/foundation.dart';


class ApiConfig 
{
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://portfolioproject-production-2b3b.up.railway.app';
    }

    // أثناء التطوير على محاكي Android
    return 'http://10.0.2.2:3000';
  }
}
