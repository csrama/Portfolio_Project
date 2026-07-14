import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/dependent.dart';
import '../services/medication_service.dart';
import '../repositories/medication_repository.dart';

class MedicationProvider extends ChangeNotifier {
  final MedicationRepository _repository;
  
  List<Medication> _medications = [];
  List<Dependent> _dependents = [];
  Medication? _selectedMedication;
  bool _isLoading = false;
  String? _errorMessage;

  List<Medication> get medications => _medications;
  List<Dependent> get dependents => _dependents;
  Medication? get selectedMedication => _selectedMedication;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMedications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _medications = await _repository.getMedicationsWithDependents();
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
      final newMed = await _medicationService.addMedication(medication);
      _medications.add(newMed);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<Medication> getActiveMedications() {
    return _medications.where((m) => m.isActive).toList();
  }

  List<Medication> getExpiredMedications() {
    return _medications.where((m) => m.isExpired).toList();
  }

  List<Medication> getMedicationsForDependent(String dependentId) {
    return _medications.where((m) => m.dependentId == dependentId).toList();
  }

  double getOverallAdherenceRate() {
    if (_medications.isEmpty) return 0.0;
    
    final total = _medications.length;
    final active = _medications.where((m) => m.isActive).length;
    return active / total * 100;
  }

  List<Medication> getMedicationsByTime(String time) {
    return _medications.where((m) => m.times.contains(time)).toList();
  }

  List<Medication> getMedicationsWithInteractions() {
    return _medications.where((m) => m.interactions != null && m.interactions!.isNotEmpty).toList();
  }
}
