import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _prodUrl = 'https://portfolioproject-production-2b3b.up.railway.app';
  static const String _localUrl = 'http://10.0.2.2:3000';


  static String get baseUrl 
  {

    return _prodUrl;
    
    
  }
}
