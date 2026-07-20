import 'api_service.dart';
import '../models/dependent.dart';

class DependentService {
  DependentService({required ApiService apiService});

  Future<List<Dependent>> getDependents(String token) async {
    final response = await ApiService.getJsonList(
      '/dependents',
      token: token,
    );

    return response.map((item) => Dependent.fromMap(item)).toList();
  }

  Future<Dependent> addDependent(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiService.postJson(
      '/dependents',
      body: data,
      token: token,
    );

    // The backend returns: { success: true, data: { dependent: {...}, user: {...} } }
    // Merge dependent + user fields so fromMap can parse them
    final dataMap = response['data'] as Map<String, dynamic>? ?? {};
    final dependentMap = dataMap['dependent'] as Map<String, dynamic>? ?? {};
    final userMap = dataMap['user'] as Map<String, dynamic>? ?? {};

    // Merge: use dependent fields as base, user fields for name/id
    dependentMap['full_name'] = userMap['full_name'] ?? dependentMap['user']?['full_name'];
    dependentMap['user_full_name'] = userMap['full_name'];
    dependentMap['user_id'] = userMap['id'];

    return Dependent.fromMap(dependentMap);
  }

  Future<List<dynamic>> getDependentMedications(
    String token,
    String dependentId,
  ) async {
    final response = await ApiService.getJsonList(
      '/dependents/$dependentId/medications',
      token: token,
    );

    return response;
  }
}
