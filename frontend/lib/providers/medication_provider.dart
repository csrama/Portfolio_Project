import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';

class MedicationProvider extends ChangeNotifier {
  final MedicationService _service = MedicationService();

  List<Medication> _medications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Medication> get medications => _medications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMedications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _medications = await _service.fetchMedications();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMedication(Medication medication) async {
    try {
      final newMed = await _service.createMedication(
        name: medication.name,
        genericName: medication.genericName,
        dosage: medication.dosage,
        form: medication.form,
        times: medication.times,
        daysOfWeek: medication.daysOfWeek,
        dependentId: medication.dependentId,
        instructions: medication.instructions,
        notes: null,  
        prescribedBy: null,  
        startDate: medication.startDate,
        endDate: medication.endDate,
        interactions: medication.interactions,
        imageUrl: null,
      );
      _medications.add(newMed);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedication(String id) async {
    try {
      final success = await _service.deleteMedication(id);
      if (success) {
        _medications.removeWhere((m) => m.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleMedicationStatus(String id) async {
    try {
      final updated = await _service.toggleMedicationStatus(id);
      final index = _medications.indexWhere((m) => m.id == id);
      if (index != -1) {
        _medications[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _medications = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
