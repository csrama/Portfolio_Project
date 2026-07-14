import '../models/medication.dart';
import '../models/dose_record.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MedicationService {
  final AuthService _authService = AuthService();

 
  List<Medication> _mapMedications(List<Map<String, dynamic>> payload) {
    return payload.map((item) {
      return Medication.fromJson(item);
    }).toList();
  }

  Medication _mapMedication(Map<String, dynamic> payload) {
    return Medication.fromJson(payload);
  }

  Future<List<Medication>> fetchMedications() async {
    final token = await _authService.getToken();
    final payload = await ApiService.getJsonDynamic(
      '/medications',
      token: token,
    );

    if (payload is List) {
      return _mapMedications(
        payload
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
    }

    if (payload is Map<String, dynamic>) {
      final list = payload['data'] ?? payload['medications'];
      if (list is List) {
        return _mapMedications(
          list
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      }
    }

    return [];
  }

  Future<List<Medication>> fetchMedicationsForDependent(
    String dependentId,
  ) async {
    final token = await _authService.getToken();
    final payload = await ApiService.getJsonDynamic(
      '/medications?dependentId=$dependentId',
      token: token,
    );

    if (payload is List) {
      return _mapMedications(
        payload
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
    }

    if (payload is Map<String, dynamic>) {
      final list = payload['data'] ?? payload['medications'];
      if (list is List) {
        return _mapMedications(
          list
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      }
    }

    return [];
  }

  Future<Medication?> fetchMedicationById(String id) async {
    final token = await _authService.getToken();
    final payload = await ApiService.getJsonDynamic(
      '/medications/$id',
      token: token,
    );

    if (payload is Map<String, dynamic>) {
      return _mapMedication(payload);
    }

    return null;
  }

  Future<Medication> createMedication({
    required String name,
    required String genericName,
    required String dosage,
    required String form,
    required List<String> times, 
    required String dependentId, 
    String? instructions,
    String? notes,
    String? prescribedBy,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? interactions,
    String? imageUrl,
  }) async {
    final token = await _authService.getToken();
    
    final medication = Medication(
      id: '', 
      name: name,
      genericName: genericName,
      dosage: dosage,
      form: form,
      times: times,
      dependentId: dependentId,
      instructions: instructions,
      notes: notes,
      prescribedBy: prescribedBy,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate,
      interactions: interactions,
      imageUrl: imageUrl,
      isActive: true,
    );

    final payload = await ApiService.postJson(
      '/medications',
      body: medication.toJson(),
      token: token,
    );

    return _mapMedication(payload);
  }

  Future<Medication> updateMedication(Medication medication) async {
    final token = await _authService.getToken();
    final payload = await ApiService.putJson(
      '/medications/${medication.id}',
      body: medication.toJson(),
      token: token,
    );

    return _mapMedication(payload);
  }

  Future<bool> deleteMedication(String id) async {
    final token = await _authService.getToken();
    try {
      await ApiService.deleteJson(
        '/medications/$id',
        token: token,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Medication> toggleMedicationStatus(String id) async {
    final token = await _authService.getToken();
    final payload = await ApiService.patchJson(
      '/medications/$id/toggle',
      token: token,
    );

    return _mapMedication(payload);
  }

  Future<List<DoseRecord>> fetchDoseRecords(String medicationId) async {
    final token = await _authService.getToken();
    final payload = await ApiService.getJsonDynamic(
      '/medications/$medicationId/doses',
      token: token,
    );

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => DoseRecord.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (payload is Map<String, dynamic>) {
      final list = payload['data'] ?? payload['doses'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((item) => DoseRecord.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    return [];
  }

  Future<DoseRecord> recordDose({
    required String medicationId,
    required String dependentId,
    required DateTime scheduledTime,
    required bool isTaken,
    String? note,
  }) async {
    final token = await _authService.getToken();
    final payload = await ApiService.postJson(
      '/doses',
      body: {
        'medication_id': medicationId,
        'dependent_id': dependentId,
        'scheduled_time': scheduledTime.toIso8601String(),
        'is_taken': isTaken,
        'taken_by': await _getCurrentUserId(),
        'note': note,
      },
      token: token,
    );

    return DoseRecord.fromJson(payload);
  }

  Future<List<DoseRecord>> fetchTodayDoses(String dependentId) async {
    final token = await _authService.getToken();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final payload = await ApiService.getJsonDynamic(
      '/doses?dependentId=$dependentId&from=${startOfDay.toIso8601String()}&to=${endOfDay.toIso8601String()}',
      token: token,
    );

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => DoseRecord.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> checkInteractions(
    List<String> medicationNames,
  ) async {
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

  Future<List<Map<String, dynamic>>> checkInteractionsByIds(
    List<String> medicationIds,
  ) async {
    if (medicationIds.length < 2) {
      return [];
    }

    final medications = <Medication>[];
    for (final id in medicationIds) {
      final med = await fetchMedicationById(id);
      if (med != null) {
        medications.add(med);
      }
    }

    final genericNames = medications.map((m) => m.genericName).toList();

    if (genericNames.length < 2) {
      return [];
    }

    return checkInteractions(genericNames);
  }

  Future<double> calculateAdherenceRate(String dependentId) async {
    final doses = await fetchTodayDoses(dependentId);
    if (doses.isEmpty) return 0.0;

    final total = doses.length;
    final taken = doses.where((d) => d.isTaken).length;

    return (taken / total) * 100;
  }

  Future<List<Medication>> fetchActiveMedications() async {
    final all = await fetchMedications();
    return all.where((m) => m.isActive).toList();
  }

  Future<List<Medication>> fetchExpiredMedications() async {
    final all = await fetchMedications();
    return all.where((m) => m.isExpired).toList();
  }

  Future<List<Medication>> fetchDueMedications() async {
    final all = await fetchMedications();
    return all.where((m) => m.isActive && m.isTimeToTake).toList();
  }


  Future<String> _getCurrentUserId() async {
    final token = await _authService.getToken();
    return 'current_user_id';
  }
}
