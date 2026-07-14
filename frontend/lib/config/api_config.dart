import 'environment.dart';

class ApiConfig {
  static String get baseUrl => Environment.baseUrl;

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  
  static const String dependents = '/dependents';
  static const String medications = '/medications';
  static const String doses = '/doses';
  static const String interactions = '/interactions';
  static const String schedule = '/schedule';

  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  static Map<String, String> get defaultHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Map<String, String> authHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }
}
