import 'package:flutter/material.dart';
import '../models/dependent.dart';
import '../services/dependent_service.dart';

class DependentProvider extends ChangeNotifier {
  final DependentService _dependentService;
  List<Dependent> _dependents = [];
  Dependent? _selectedDependent;
  bool _isLoading = false;

  DependentProvider({required DependentService dependentService}) : _dependentService = dependentService;

  List<Dependent> get dependents => _dependents;
  Dependent? get selectedDependent => _selectedDependent;
  bool get isLoading => _isLoading;

  Future<void> fetchDependents(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _dependents = await _dependentService.getDependents(token);
    } catch (e) {
      debugPrint('Error fetching dependents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDependent(Dependent? dependent) {
    _selectedDependent = dependent;
    notifyListeners();
  }

  Future<void> addDependent(String token, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newDependent = await _dependentService.addDependent(token, data);
      _dependents.add(newDependent);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding dependent: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
