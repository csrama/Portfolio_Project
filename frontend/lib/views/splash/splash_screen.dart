import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../dashboard/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../dashboard/home_screen.dart';
import '../../repositories/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late Timer _timer;

  static final _pages = [
    _SplashPage(
      title: 'دوائي',
      child: Image.asset(
        'assets/app_icon.png',
        width: 120,
        height: 120,
      ),
    ),
    _SplashPage(
      child: Text(
        'مرحبا بك في تطبيق دوائي',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D9E75),
        ),
      ),
    ),
    _SplashPage(
      child: Text(
        'حيث أن دوائك في وقته',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D9E75),
        ),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_currentPage < _pages.length - 1) {
        _currentPage++;
        _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel();
        final authService = AuthService();
        final hasSession = await authService.hasSession();
        final userName = hasSession ? await authService.getStoredUserName() : null;

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => hasSession
                ? 

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
                : const OnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFE8F1E9), Color(0xFFB6D3C2)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: PageView.builder(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _pages[index],
          ),
        ),
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  final Widget child;
  final String? title;

  const _SplashPage({required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (title != null) ...[
            const SizedBox(height: 24),
            Text(
              title!,
              style: const TextStyle(
                color: Color(0xFF1D9E75),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
