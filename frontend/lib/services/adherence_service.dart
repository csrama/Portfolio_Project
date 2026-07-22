import 'api_service.dart';

class AdherenceService {
  /// Fetches the adherence rate from the backend.
  /// Returns a map with { adherence_rate, completed, total }.
  static Future<Map<String, dynamic>> getAdherenceRate(String token) async {
    try {
      final result = await ApiService.getJsonDynamic(
        '/adherence/rate',
        token: token,
      );
      if (result is Map<String, dynamic>) {
        return result;
      }
      return {'adherence_rate': 0, 'completed': 0, 'total': 0};
    } catch (e) {
      return {'adherence_rate': 0, 'completed': 0, 'total': 0};
    }
  }

  /// Fetches the dose log history from the backend.
  static Future<List<dynamic>> getDoseLogs(String token) async {
    try {
      return await ApiService.getJsonList(
        '/dose-logs',
        token: token,
      );
    } catch (e) {
      return [];
    }
  }
}

