import '../models/medication.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MedicationService {
  final AuthService _authService = AuthService();

 
  Future<List<Medication>> fetchMedications() async {
    final token = await _authService.getAccessToken();
    if (token == null) return [];

    try {
      final response = await ApiService.getJsonList(
        '/medications',
        token: token,
      );

      return response
          .whereType<Map<String, dynamic>>()
          .map((json) => Medication.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Medication?> fetchMedicationById(String id) async {
    final token = await _authService.getAccessToken();
    if (token == null) return null;

    try {
      final response = await ApiService.getJsonMap(
        '/medications/$id',
        token: token,
      );

      return Medication.fromJson(response);
    } catch (e) {
      return null;
    }
  }


  Future<Medication> createMedication({
    required String name,
    required String genericName,
    required String dosage,
    required String form,
    required List<String> times,
    required List<String> daysOfWeek,
    required String dependentId,
    String? instructions,
    String? notes,
    String? prescribedBy,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? interactions,
    String? imageUrl,
  }) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final body = {
      'name': name,
      'generic_name': genericName,
      'dosage': dosage,
      'form': form,
      'times': times,
      'days_of_week': daysOfWeek,
      'dependent_id': dependentId,
      if (instructions != null) 'instructions': instructions,
      if (notes != null) 'notes': notes,
      if (prescribedBy != null) 'prescribed_by': prescribedBy,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (interactions != null) 'interactions': interactions,
      if (imageUrl != null) 'image_url': imageUrl,
    };

    try {
      final response = await ApiService.postJson(
        '/medications',
        body: body,
        token: token,
      );

      return Medication.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create medication: $e');
    }
  }

  

  Future<Medication> updateMedication(Medication medication) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await ApiService.putJson(
        '/medications/${medication.id}',
        body: medication.toJson(),
        token: token,
      );

      return Medication.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update medication: $e');
    }
  }


  Future<bool> deleteMedication(String id) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      await ApiService.deleteJson(
        '/medications/$id',
        token: token,
      );
      return true;
    } catch (e) {
      throw Exception('Failed to delete medication: $e');
    }
  }


  Future<Medication> toggleMedicationStatus(String id) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await ApiService.patchJson(
        '/medications/$id/toggle',
        body: {},
        token: token,
      );

      return Medication.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle medication status: $e');
    }
  }
}
