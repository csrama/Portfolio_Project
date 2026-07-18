import '../models/medication_summary.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MedicationService {
  final AuthService _authService = AuthService();

  List<MedicationSummary> mapMedications(List<Map<String, dynamic>> payload) {
    return payload.map((item) {
      final id = item['id'];
      final name = (item['name'] ?? '').toString();
      final dosage = (item['dosage'] ?? '').toString();
      final form = (item['form'] ?? 'tablet').toString();
      final instructions = (item['instructions'] ?? '').toString();
      final isActive = item['is_active'] != false;

      return MedicationSummary(
        id: id is int ? id : int.tryParse(id.toString()) ?? 0,
        name: name,
        dosage: dosage,
        form: form,
        instructions: instructions,
        isActive: isActive,
      );
    }).toList();
  }

  Future<List<MedicationSummary>> fetchMedications() async {
    final token = await _authService.getToken();
    final payload =
        await ApiService.getJsonDynamic('/medications', token: token);

    if (payload is List) {
      return mapMedications(
        payload
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
    }

    if (payload is Map<String, dynamic>) {
      final list = payload['medications'];
      if (list is List) {
        return mapMedications(list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList());
      }
    }

    return [];
  }

  Future<MedicationSummary> createMedication({
    required String name,
    required String dosage,
    required String form,
    String? instructions,
  }) async {
    final token = await _authService.getToken();
    final payload = await ApiService.postJson(
      '/medications',
      body: {
        'name': name,
        'dosage': dosage,
        'form': form,
        if (instructions != null && instructions.isNotEmpty)
          'instructions': instructions,
      },
      token: token,
    );

    return MedicationSummary(
      id: payload['id'] is int
          ? payload['id'] as int
          : int.tryParse(payload['id'].toString()) ?? 0,
      name: (payload['name'] ?? '').toString(),
      dosage: (payload['dosage'] ?? '').toString(),
      form: (payload['form'] ?? form).toString(),
      instructions: (payload['instructions'] ?? '').toString(),
      isActive: payload['is_active'] != false,
    );
  }

  Future<List<Map<String, dynamic>>> checkInteractions(
      List<String> medicationNames) async {
    if (medicationNames.length < 2) {
      return [];
    }

    final token = await _authService.getToken();
    final payload = await ApiService.postJson(
      '/interactions/check',
      body: {'generic_names': medicationNames},
      token: token,
    );

    if (payload['interactions'] is List) {
      return List<Map<String, dynamic>>.from(payload['interactions']);
    }

    return [];
  }
}
