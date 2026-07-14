import '../models/dependent.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DependentService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  
  Future<String?> getAccessToken() async {
    return await _authService.getAccessToken();
  }

  Future<AuthInfo> getAuth() async {
    final token = await getAccessToken();
    return AuthInfo(token: token);
  }

  Future<List<Dependent>> fetchDependents([String? token]) async {
    final authToken = token ?? await getAccessToken();
    
    if (authToken == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _apiService.getJsonDynamic(
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
      final response = await _apiService.getJsonDynamic(
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

  Future<Dependent> addDependent(
    Map<String, dynamic> data, [
    String? token,
  ]) async {
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
      final response = await _apiService.postJson(
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

  
  Future<Dependent> updateDependent(
    String id,
    Map<String, dynamic> data, [
    String? token,
  ]) async {
    final authToken = token ?? await getAccessToken();
    
    if (authToken == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _apiService.putJson(
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
      await _apiService.deleteJson(
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
      final dependents = await fetchDependents(authToken);
      return dependents;
    } catch (e) {
      throw Exception('Failed to sync dependents: $e');
    }
  }

  Future<int> getDependentsCount([String? token]) async {
    final dependents = await fetchDependents(token);
    return dependents.length;
  }

  Future<List<Dependent>> getActiveDependents([String? token]) async {
    final all = await fetchDependents(token);
    return all.where((d) => d.isActive).toList();
  }
}


class AuthInfo {
  final String? token;
  final String? userId;

  AuthInfo({this.token, this.userId});

  bool get isAuthenticated => token != null && token!.isNotEmpty;
}
