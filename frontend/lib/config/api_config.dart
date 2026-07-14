
import 'environment.dart';

class ApiConfig {
  static String get baseUrl => Environment.baseUrl;
  
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  static const String dependents = '/dependents';
  static String dependentById(String id) => '/dependents/$id';
  static String dependentMedications(String id) => '/dependents/$id/medications';
  static String dependentSchedule(String id) => '/dependents/$id/schedule';

  static const String medications = '/medications';
  static String medicationById(String id) => '/medications/$id';
  static String medicationDoses(String id) => '/medications/$id/doses';
  static String medicationToggle(String id) => '/medications/$id/toggle';

  static const String doses = '/doses';
  static String doseById(String id) => '/doses/$id';
  static String dosesByDate(String date) => '/doses?date=$date';
  static String dosesByDependent(String dependentId) => '/doses?dependentId=$dependentId';

  static const String interactions = '/interactions';
  static const String interactionsCheck = '/interactions/check';

  static String getUrl(String path) {
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }

  static String getUrlWithParams(String path, {Map<String, dynamic>? params}) {
    final uri = Uri.parse(getUrl(path));
    if (params == null || params.isEmpty) return uri.toString();
    return uri.replace(
      queryParameters: params.map((key, value) => MapEntry(key, value.toString())),
    ).toString();
  }


  static Map<String, String> get defaultHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': Environment.version,
    };
  }

  static Map<String, String> authHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  static void printEndpoints() {
    print('========================================');
    print(' API Endpoints');
    print('========================================');
    print('Base URL: $baseUrl');
    print('----------------------------------------');
    print(' Auth:');
    print('  Login: $authLogin');
    print('  Register: $authRegister');
    print('  Refresh: $authRefresh');
    print('----------------------------------------');
    print(' Dependents:');
    print('  List: $dependents');
    print('----------------------------------------');
    print(' Medications:');
    print('  List: $medications');
    print('========================================');
  }
}
