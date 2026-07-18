import 'api_service.dart';
import '../models/dependent.dart';

class DependentService {
  final ApiService _apiService;

  DependentService({required ApiService apiService})
      : _apiService = apiService;

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

    return Dependent.fromMap(response);
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
