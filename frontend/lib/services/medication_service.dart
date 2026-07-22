import '../models/medication_summary.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MedicationService {
  final AuthService _authService = AuthService();

  List<MedicationSummary> mapMedications(List<Map<String, dynamic>> payload) {
    return payload.map((item) {
      final id = item['id'];
      final name = (item['name_en'] ?? item['name'] ?? '').toString();
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

  //  جلب جميع الأدوية
  Future<List<MedicationSummary>> fetchMedications() async {
    final token = await _authService.getToken();
    
    try {
      final payload = await ApiService.getJsonDynamic('/medicines', token: token);
      print(' fetchMedications response: $payload');

      if (payload is List) {
        return mapMedications(
          payload
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      }

      if (payload is Map<String, dynamic>) {
        final list = payload['data'] ?? payload['medications'];
        if (list is List) {
          return mapMedications(list
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList());
        }
      }

      print(' No medications found');
      return [];
    } catch (e) {
      print(' fetchMedications error: $e');
      return [];
    }
  }

  //  البحث عن دواء
  Future<List<MedicationSummary>> searchMedicines(String query) async {
    if (query.isEmpty) {
      return fetchMedications();
    }

    final token = await _authService.getToken();
    
    try {
      final payload = await ApiService.getJsonDynamic(
        '/medicines/search?q=$query',
        token: token,
      );
      print(' searchMedicines response: $payload');

      if (payload is List) {
        return mapMedications(
          payload
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      }

      if (payload is Map<String, dynamic>) {
        final list = payload['data'] ?? payload['medications'] ?? payload['results'];
        if (list is List) {
          return mapMedications(list
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList());
        }
      }

      print(' No search results');
      return [];
    } catch (e) {
      print(' searchMedicines error: $e');
      return [];
    }
  }

  //  إنشاء دواء جديد
  Future<MedicationSummary> createMedication({
    required String name,
    required String dosage,
    required String form,
    String? instructions,
  }) async {
    final token = await _authService.getToken();
    print('➕ Adding medication: $name');

    try {
      final payload = await ApiService.postJson(
        '/medicines',
        body: {
          'name': name,
          'dosage': dosage,
          'form': form,
          if (instructions != null && instructions.isNotEmpty)
            'instructions': instructions,
        },
        token: token,
      );

      print(' Added: $payload');

      return MedicationSummary(
        id: payload['id'] is int
            ? payload['id'] as int
            : int.tryParse(payload['id'].toString()) ?? 0,
        name: (payload['name_en'] ?? payload['name'] ?? name).toString(),
        dosage: (payload['dosage'] ?? dosage).toString(),
        form: (payload['form'] ?? form).toString(),
        instructions: (payload['instructions'] ?? '').toString(),
        isActive: payload['is_active'] != false,
      );
    } catch (e) {
      print('❌ Add error: $e');
      throw Exception('Failed to add medication: $e');
    }
  }

  //  التحقق من التفاعلات الدوائية
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

  //  حذف دواء
  Future<void> deleteMedication(int id) async {
    final token = await _authService.getToken();
    await ApiService.delete('/medicines/$id', token: token ?? '');
  }

  // تحديث دواء
  Future<MedicationSummary> updateMedication({
    required int id,
    String? name,
    String? dosage,
    String? form,
    String? instructions,
    bool? isActive,
  }) async {
    final token = await _authService.getToken();
    final payload = await ApiService.patchJson(
      '/medicines/$id',
      body: {
        if (name != null) 'name': name,
        if (dosage != null) 'dosage': dosage,
        if (form != null) 'form': form,
        if (instructions != null) 'instructions': instructions,
        if (isActive != null) 'is_active': isActive,
      },
      token: token,
    );

    return MedicationSummary(
      id: payload['id'] is int
          ? payload['id'] as int
          : int.tryParse(payload['id'].toString()) ?? 0,
      name: (payload['name_en'] ?? payload['name'] ?? '').toString(),
      dosage: (payload['dosage'] ?? '').toString(),
      form: (payload['form'] ?? '').toString(),
      instructions: (payload['instructions'] ?? '').toString(),
      isActive: payload['is_active'] != false,
    );
  }
}