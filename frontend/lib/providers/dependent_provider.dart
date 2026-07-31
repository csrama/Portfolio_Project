import 'package:flutter/material.dart';
import '../models/dependent.dart';
import '../services/dependent_service.dart';

class DependentProvider extends ChangeNotifier {
  final DependentService _dependentService;
  List<Dependent> _dependents = [];
  List<dynamic> _incomingRequests = [];
  Dependent? _selectedDependent;
  bool _isLoading = false;

  DependentProvider({required DependentService dependentService})
    : _dependentService = dependentService;

  List<Dependent> get dependents => _dependents;
  List<dynamic> get incomingRequests => _incomingRequests;
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

  Future<Map<String, dynamic>> addDependent(
    String token,
    Map<String, dynamic> data,
  ) async {
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

  Future<Map<String, dynamic>> addDependentDirect(
    String token,
    Map<String, dynamic> data,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dependentService.addDependentDirect(token, data);
      if (response['success'] == true) {
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

  Future<bool> updateDependent(
    String token,
    String dependentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dependentService.updateDependent(
        token,
        dependentId,
        data,
      );
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
  Future<bool> deleteDependent(String token, String dependentId) async {
    try {
      final response = await _dependentService.deleteDependent(
        token,
        dependentId,
      );
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

  Future<Map<String, dynamic>> addNewDependent(
    String token, {
    required String fullName,
    required String email,
    required String password,
    required String relationship,
    String? dateOfBirth,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dependentService.addNewDependent(
        token,
        fullName: fullName,
        email: email,
        password: password,
        relationship: relationship,
        dateOfBirth: dateOfBirth,
      );
      if (response['success'] == true) {
        await fetchDependents(token);
      }
      return response;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> sendLinkRequest(
    String token, {
    required String email,
    required String relationship,
  }) async {
    return _dependentService.sendLinkRequest(token, email: email, relationship: relationship);
  }

  Future<void> fetchIncomingRequests(String token) async {
    _incomingRequests = await _dependentService.getIncomingRequests(token);
    notifyListeners();
  }

  Future<bool> respondToRequest(String token, String requestId, bool accept) async {
    final response = await _dependentService.respondToRequest(token, requestId, accept);
    if (response['success'] == true) {
      await fetchIncomingRequests(token);
      if (accept) await fetchDependents(token);
      return true;
    }
    return false;
  }
}
