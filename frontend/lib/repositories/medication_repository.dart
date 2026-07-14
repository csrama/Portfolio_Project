import '../models/medication.dart';
import '../models/dependent.dart';
import '../services/medication_service.dart';
import '../services/dependent_service.dart';

class MedicationRepository {
  final MedicationService _medicationService;
  final DependentService _dependentService;

  MedicationRepository(this._medicationService, this._dependentService);

  Future<List<Medication>> getMedicationsWithDependents() async {
    final dependents = await _dependentService.getDependents();
    
    List<Medication> allMedications = [];
    for (var dependent in dependents) {
      final meds = await _medicationService.getMedications(dependent.id);
      allMedications.addAll(meds);
    }
    
    allMedications.sort((a, b) => a.name.compareTo(b.name));
    
    return allMedications;
  }

  Future<Map<String, dynamic>> getMedicationSummary() async {
    final medications = await getMedicationsWithDependents();
    
    final total = medications.length;
    final active = medications.where((m) => m.isActive).length;
    final expired = medications.where((m) => m.isExpired).length;
    
    return {
      'total': total,
      'active': active,
      'expired': expired,
      'expiredMedications': medications.where((m) => m.isExpired).toList(),
    };
  }
}
