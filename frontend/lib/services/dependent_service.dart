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

  Future<Map<String, dynamic>> addDependent(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiService.postJson(
      '/dependents',
      body: data,
      token: token,
    );

    // The backend returns: { success: true, data: { invite_link, token, dependent, caregiver } }
    return response;
  }

  /// Add a dependent directly without sending an invite
  Future<Map<String, dynamic>> addDependentDirect(
    String token,
    Map<String, dynamic> data,
  ) async {
    // Set invite: false to bypass the invite flow
    data['invite'] = false;
    final response = await ApiService.postJson(
      '/dependents',
      body: data,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getInviteInfo(String inviteToken) async {
    final response = await ApiService.getJsonDynamic(
      '/dependents/invite/$inviteToken',
    );

    // The backend returns: { success: true, data: { dependent_name, relationship, caregiver_name, invited_at } }
    if (response is Map<String, dynamic> && response['success'] == true) {
      return response['data'] as Map<String, dynamic>? ?? {};
    }
    throw Exception(response['error'] ?? 'فشل جلب معلومات الدعوة');
  }

  Future<Map<String, dynamic>> acceptInvite(
    String token,
    String inviteToken,
  ) async {
    final response = await ApiService.postJson(
      '/dependents/invite/$inviteToken/accept',
      body: {},
      token: token,
    );

    return response;
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

  /// Update a dependent's info
  Future<Map<String, dynamic>> updateDependent(
    String token,
    String dependentId,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiService.putJson(
      '/dependents/$dependentId',
      body: data,
      token: token,
    );
    return response;
  }

  /// Delete a dependent
  Future<Map<String, dynamic>> deleteDependent(
    String token,
    String dependentId,
  ) async {
    final response = await ApiService.deleteJson(
      '/dependents/$dependentId',
      token: token,
    );
    return response;
  }
}
