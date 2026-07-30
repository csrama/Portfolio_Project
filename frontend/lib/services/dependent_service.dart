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

    return response;
  }

  Future<Map<String, dynamic>> addDependentDirect(
    String token,
    Map<String, dynamic> data,
  ) async {
    data['invite'] = false;
    final response = await ApiService.postJson(
      '/dependents',
      body: data,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> addNewDependent(
    String token, {
    required String fullName,
    required String email,
    required String password,
    required String relationship,
    String? dateOfBirth,
  }) async {
    return ApiService.postJson(
      '/dependents/create-with-account',
      token: token,
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'relationship': relationship,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      },
    );
  }

  Future<Map<String, dynamic>> sendLinkRequest(
    String token, {
    required String email,
    required String relationship,
  }) async {
    return ApiService.postJson(
      '/dependents/link-request',
      token: token,
      body: {'email': email, 'relationship': relationship},
    );
  }

  Future<List<dynamic>> getIncomingRequests(String token) async {
    return ApiService.getJsonList('/dependents/requests', token: token);
  }

  Future<Map<String, dynamic>> respondToRequest(
    String token,
    String requestId,
    bool accept,
  ) async {
    final action = accept ? 'accept' : 'reject';
    return ApiService.postJson(
      '/dependents/requests/$requestId/$action',
      token: token,
      body: {},
    );
  }

  Future<Map<String, dynamic>> getInviteInfo(String inviteToken) async {
    final response = await ApiService.getJsonDynamic(
      '/dependents/invite/$inviteToken',
    );

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
