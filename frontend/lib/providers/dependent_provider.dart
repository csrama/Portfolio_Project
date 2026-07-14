import 'package:flutter/material.dart';
import '../models/dependent.dart';
import '../services/dependent_service.dart';
import '../services/auth_service.dart';

class DependentProvider extends ChangeNotifier {
  

  final DependentService _service = DependentService();
  final AuthService _authService = AuthService();

 

  List<Dependent> _dependents = [];
  Dependent? _selectedDependent;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  

  List<Dependent> get dependents => _dependents;
  Dependent? get selectedDependent => _selectedDependent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get hasDependents => _dependents.isNotEmpty;

  Dependent? get currentDependent {
    if (_selectedDependent != null) return _selectedDependent;
    if (_dependents.isNotEmpty) return _dependents.first;
    return null;
  }

  int get count => _dependents.length;

  List<Dependent> get activeDependents =>
      _dependents.where((d) => d.isActive).toList();

  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final hasSession = await _authService.hasSession();
      if (hasSession) {
        await fetchDependents();
      }
      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDependents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dependents = await _service.fetchDependents();
      
      if (_selectedDependent != null) {
        final stillExists = _dependents.any(
          (d) => d.id == _selectedDependent!.id,
        );
        if (!stillExists) {
          _selectedDependent = null;
        }
      }

      if (_selectedDependent == null && _dependents.isNotEmpty) {
        _selectedDependent = _dependents.first;
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching dependents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDependents() async {
    await fetchDependents();
  }

  Future<bool> addDependent({
    required String name,
    required String relationship,
    Map<String, dynamic>? additionalData,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'full_name': name.trim(),
        'relationship': relationship.trim(),
        ...?additionalData,
      };

      final newDependent = await _service.addDependent(data);

      _dependents.add(newDependent);
      
      if (_selectedDependent == null) {
        _selectedDependent = newDependent;
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error adding dependent: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDependent({
    required String id,
    String? name,
    String? relationship,
    bool? isActive,
    Map<String, dynamic>? additionalData,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        if (name != null) 'full_name': name.trim(),
        if (relationship != null) 'relationship': relationship.trim(),
        if (isActive != null) 'is_active': isActive,
        ...?additionalData,
      };

      final updatedDependent = await _service.updateDependent(id, data);

      final index = _dependents.indexWhere((d) => d.id == id);
      if (index != -1) {
        _dependents[index] = updatedDependent;
      }

      if (_selectedDependent?.id == id) {
        _selectedDependent = updatedDependent;
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating dependent: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDependent(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.deleteDependent(id);

      if (success) {
        _dependents.removeWhere((d) => d.id == id);

        if (_selectedDependent?.id == id) {
          _selectedDependent = _dependents.isNotEmpty ? _dependents.first : null;
        }

        _errorMessage = null;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting dependent: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDependent(Dependent? dependent) {
    if (dependent != null) {
      final exists = _dependents.any((d) => d.id == dependent.id);
      if (!exists) {
        debugPrint('Dependent not found in list');
        return;
      }
    }

    _selectedDependent = dependent;
    notifyListeners();
  }

  bool selectDependentById(String id) {
    final dependent = _dependents.firstWhere(
      (d) => d.id == id,
      orElse: () => throw Exception('Dependent not found'),
    );
    
    if (dependent != null) {
      selectDependent(dependent);
      return true;
    }
    return false;
  }

  void clearSelection() {
    _selectedDependent = null;
    notifyListeners();
  }

 
  Future<void> syncDependents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final synced = await _service.syncDependents();
      _dependents = synced;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error syncing dependents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  
  int get activeCount => _dependents.where((d) => d.isActive).length;

  int get inactiveCount => _dependents.where((d) => !d.isActive).length;

  String get selectedDependentName =>
      _selectedDependent?.fullName ?? 'غير محدد';

  List<Dependent> searchDependents(String query) {
    if (query.trim().isEmpty) return _dependents;
    
    final lowerQuery = query.toLowerCase().trim();
    return _dependents.where((d) {
      return d.fullName.toLowerCase().contains(lowerQuery) ||
          d.relationship.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Dependent> getDependentsByRelationship(String relationship) {
    return _dependents
        .where((d) => d.relationship.toLowerCase() == relationship.toLowerCase())
        .toList();
  }

  void clear() {
    _dependents = [];
    _selectedDependent = null;
    _isLoading = false;
    _errorMessage = null;
    _isInitialized = false;
    notifyListeners();
  }

  bool isSelected(Dependent dependent) {
    return _selectedDependent?.id == dependent.id;
  }

  Dependent? getDependentById(String id) {
    try {
      return _dependents.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  bool get isEmpty => _dependents.isEmpty;

  bool get isNotEmpty => _dependents.isNotEmpty;
  Future<bool> toggleDependentStatus(String id) async {
    final dependent = getDependentById(id);
    if (dependent == null) return false;

    return updateDependent(
      id: id,
      isActive: !dependent.isActive,
    );
  }
}
