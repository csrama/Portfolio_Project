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

  Future<Map<String, dynamic>> addDependent(String token, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dependentService.addDependent(token, data);
      return response;
    } catch (e) {
      debugPrint('Error adding dependent: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a dependent directly without sending an invite
  Future<Map<String, dynamic>> addDependentDirect(String token, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dependentService.addDependentDirect(token, data);
      if (response['success'] == true) {
        // Refresh the dependents list
        await fetchDependents(token);
      }
      return response;
    } catch (e) {
      debugPrint('Error adding dependent directly: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a dependent's info
  Future<bool> updateDependent(String token, String dependentId, Map<String, dynamic> data) async {
    try {
      final response = await _dependentService.updateDependent(token, dependentId, data);
      if (response['success'] == true) {
        await fetchDependents(token);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating dependent: $e');
      return false;
    }
  }

  /// Delete a dependent
  Future<bool> deleteDependent(String token, String dependentId) async {
    try {
      final response = await _dependentService.deleteDependent(token, dependentId);
      if (response['success'] == true) {
        await fetchDependents(token);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting dependent: $e');
      return false;
    }
  }
}
