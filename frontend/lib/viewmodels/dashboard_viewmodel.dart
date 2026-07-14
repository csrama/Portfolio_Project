import '../models/medication.dart';
import '../models/dependent.dart';
import '../models/medication_summary.dart';
import '../providers/medication_provider.dart';
import '../providers/auth_provider.dart';

class DashboardViewModel {
  final MedicationProvider _medicationProvider;
  final AuthProvider _authProvider;

  DashboardViewModel(this._medicationProvider, this._authProvider);

  MedicationSummary getSummary() {
    final medications = _medicationProvider.medications;
    final user = _authProvider.currentUser;

    return MedicationSummary(
      totalMedications: medications.length,
      activeMedications: medications.where((m) => m.isActive).length,
      dosesToday: _getDosesForToday(medications),
      dosesTakenToday: _getTakenDosesForToday(medications),
      missedDoses: _getMissedDoses(medications),
      upcomingDoses: _getUpcomingDoses(medications),
      adherenceRateToday: _calculateAdherenceToday(medications),
      adherenceRateWeek: _calculateAdherenceWeek(medications),
      interactions: _getAllInteractions(medications),
    );
  }

  int _getDosesForToday(List<Medication> medications) {
    int count = 0;
    for (var med in medications) {
      if (med.isActive) {
        count += med.times.length;
      }
    }
    return count;
  }

  int _getTakenDosesForToday(List<Medication> medications) {
    return 0; 
  }

  int _getMissedDoses(List<Medication> medications) {
    return 0; 
  }

  int _getUpcomingDoses(List<Medication> medications) {
    int count = 0;
    final now = DateTime.now();
    
    for (var med in medications) {
      if (!med.isActive) continue;
      
      for (var time in med.times) {
        final timeParts = time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final doseTime = DateTime(now.year, now.month, now.day, hour, minute);
        
        if (doseTime.isAfter(now) && doseTime.difference(now).inMinutes <= 60) {
          count++;
        }
      }
    }
    return count;
  }

  double _calculateAdherenceToday(List<Medication> medications) {
    return 85.5; 
  }

  double _calculateAdherenceWeek(List<Medication> medications) {
    return 78.0; 
  }

  List<String> _getAllInteractions(List<Medication> medications) {
    final allInteractions = <String>[];
    for (var med in medications) {
      if (med.interactions != null) {
        allInteractions.addAll(med.interactions!);
      }
    }
    return allInteractions.toSet().toList(); 
  }

  List<Map<String, dynamic>> getWeeklyAdherenceData() {
    final medications = _medicationProvider.medications;
    return [];
  }


  List<Map<String, String>> getUpcomingDosesNotifications() {
    final notifications = <Map<String, String>>[];
    final medications = _medicationProvider.medications;
    
    for (var med in medications) {
      if (!med.isActive) continue;
      
      for (var time in med.times) {
        notifications.add({
          'medicationName': med.name,
          'time': time,
          'dosage': med.dosage,
          'status': 'pending',
        });
      }
    }
    
    notifications.sort((a, b) => a['time']!.compareTo(b['time']!));
    return notifications;
  }
}
