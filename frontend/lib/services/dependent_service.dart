import '../models/dependent.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DependentService {
  final AuthService _authService = AuthService();

  Future<String?> getAccessToken() async {
    return await _authService.getAccessToken();
  }

  Future<List<Dependent>> fetchDependents([String? token]) async {
    final authToken = token ?? await getAccessToken();
    
    if (authToken == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await ApiService.getJsonDynamic(
        '/dependents',
        token: authToken,
      );

      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map((json) => Dependent.fromJson(json))
            .toList();
      }

      if (response is Map<String, dynamic>) {
        final list = response['data'] ?? response['dependents'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((json) => Dependent.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch dependents: $e');
    }
  }

  Future<Dependent?> fetchDependentById(String id, [String? token]) async {
    final authToken = token ?? await getAccessToken();
    
    if (authToken == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await ApiService.getJsonDynamic(
        '/dependents/$id',
        token: authToken,
      );

      if (response is Map<String, dynamic>) {
        return Dependent.fromJson(response);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch dependent: $e');
    }
  }

  Future<Dependent> addDependent(Map<String, dynamic> data, [String? token]) async {
    final authToken = token ?? await getAccessToken();
    
    if (authToken == null) {
      throw Exception('User not authenticated');
    }

    final name = data['full_name']?.toString().trim();
    final relationship = data['relationship']?.toString().trim();

    if (name == null || name.isEmpty) {
      throw Exception('Full name is required');
    }

    if (relationship == null || relationship.isEmpty) {
      throw Exception('Relationship is required');
    }

    try {
      final response = await ApiService.postJson(
        '/dependents',
        body: {
          'full_name': name,
          'relationship': relationship,
          'is_active': data['is_active'] ?? true,
        },
        token: authToken,
      );

      return Dependent.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add dependent: $e');
    }
  }

  Future<Dependent> updateDependent(String id, Map<String, dynamic> data, [String? token]) async {
    final authToken = token ?? await getAccessToken();
    
    if (authToken == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await ApiService.putJson(
        '/dependents/$id',
        body: data,
        token: authToken,
      );

      return Dependent.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update dependent: $e');
    }
  }

  Future<bool> deleteDependent(String id, [String? token]) async {
    final authToken = token ?? await getAccessToken();
    
    if (authToken == null) {
      throw Exception('User not authenticated');
    }

    try {
      await ApiService.deleteJson(
        '/dependents/$id',
        token: authToken,
      );
      return true;
    } catch (e) {
      throw Exception('Failed to delete dependent: $e');
    }
  }

  Future<List<Dependent>> syncDependents([String? token]) async {
    final authToken = token ?? await getAccessToken();
    
    if (authToken == null) {
      throw Exception('User not authenticated');
    }

    try {
      return await fetchDependents(authToken);
    } catch (e) {
      throw Exception('Failed to sync dependents: $e');
    }
  }
}
