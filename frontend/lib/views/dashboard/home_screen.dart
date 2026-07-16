// lib/screens/dashboard/home_screen.dart
//
// Single drop-in replacement for the previous home_screen.dart.
// Keeps the same class name (HomeScreen) and constructor signature
// (userName, photoUrl) so existing imports/usages elsewhere in the
// project (e.g. OnboardingScreen's Navigator.pushReplacement) keep
// working without any changes.
//
// Combines:
//  - Restored "صباح الخير / مساء الخير" greeting + profile avatar (dark green)
//  - "اليوم" tab: fixed/working horizontal day strip + today's medications
//  - "أدويتي" tab: unlimited list of saved medications
//  - "+" button (top bar) opening a bottom sheet to add a medication
//  - Bottom navigation: اليوم / أدويتي / التذكيرات (same icons as before)
//
// LOCAL STATE ONLY for now (in-memory list). Swap _medications' source
// and _handleSaveMedication with real API calls once the backend
// schedules endpoint is confirmed working.

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/onboarding_screen.dart';
import '../splash/splash_screen.dart';
import '../../repositories/auth_repository.dart';
import '../../services/google_auth_service.dart';
import 'package:provider/provider.dart';
import '../../providers/dependent_provider.dart';
import 'dependents_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/dependent_service.dart';
import '../../services/api_service.dart';

// ---------------------------------------------------------------------
// Colors (inlined here to keep this a single self-contained file)
// ---------------------------------------------------------------------
class _Colors {
  static const Color primaryGreen = Color(0xFF1D9E75);
  static const Color darkGreen = Color(0xFF085041);
  static const Color lightGreenBg = Color(0xFFD9F2E7);
  static const Color mutedGreen = Color(0xFF7FBF9E);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black54;
  static const Color borderGrey = Color(0xFFE0E0E0);
}

// ---------------------------------------------------------------------
// Medication model (local, in-memory)
// ---------------------------------------------------------------------
enum MedicationType { drops, cream, injection, bottle, tablets, capsule }

extension _MedicationTypeIcon on MedicationType {
  IconData get icon {
    switch (this) {
      case MedicationType.drops:
        return Icons.opacity;
      case MedicationType.cream:
        return Icons.back_hand_outlined;
      case MedicationType.injection:
        return Icons.vaccines_outlined;
      case MedicationType.bottle:
        return Icons.medication_liquid_outlined;
      case MedicationType.tablets:
        return Icons.grain;
      case MedicationType.capsule:
        return Icons.medication_outlined;
    }
  }
}

class MedicationItem {
  final String id;
  final String name;
  final String dosage;
  final MedicationType type;
  final List<String> daysOfWeek;
  final String period; // "صباحا" | "مساء"
  final TimeOfDay time;
  final int dosesPerDay;
  final bool reminderEnabled;
  bool isActive;

  MedicationItem({
    required this.id,
    required this.name,
    required this.dosage,
    required this.type,
    required this.daysOfWeek,
    required this.period,
    required this.time,
    required this.dosesPerDay,
    this.reminderEnabled = true,
    this.isActive = true,
  });

  String get timeLabel {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

// ---------------------------------------------------------------------
// HomeScreen (public API kept identical to the original file)
// ---------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  final String? userName;
  final String? photoUrl;

  const HomeScreen({super.key, this.userName, this.photoUrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<MedicationItem> _medications =
      []; // unlimited: just a growing list
  final Set<String> _takenMedications = {}; // medication name + date key
  final Map<String, int> _doseRecordIds = {}; // نفس المفتاح -> id السجل بالباك إند

  late final List<DateTime> _dateStrip;
  late DateTime _selectedDate;

  static const List<String> _weekdayAr = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = today;
    // 7-day rolling strip centered on today, oldest first so it reads
    // naturally left-to-right even inside an RTL Directionality.
    _dateStrip = List.generate(7, (i) => today.add(Duration(days: i - 3)));
    _loadMedications();
    _loadTakenMedications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-load medications if the selected dependent changes
    _loadMedications();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'صباح الخير';
    }
    return 'مساء الخير';
  }

  String _weekdayNameFromDate(DateTime date) {
    return _weekdayAr[date.weekday - 1];
  }

  String _arabicDigits(String input) {
    const western = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    return input.split('').map((char) {
      final index = western.indexOf(char);
      return index >= 0 ? arabic[index] : char;
    }).join();
  }

  String _formatMedicationInfo(MedicationItem medication) {
    final timeLabel = _arabicDigits(medication.timeLabel);
    final count = _arabicDigits(medication.dosesPerDay.toString());
    return '$timeLabel. في اليوم/x$count';
  }

  List<MedicationItem> _medicationsForDate(DateTime date) {
    final dayName = _weekdayNameFromDate(date);
    return _medications.where((med) {
      final scheduledEveryDay = med.daysOfWeek.isEmpty;
      return med.isActive &&
          (scheduledEveryDay || med.daysOfWeek.contains(dayName));
    }).toList();
  }

  bool _hasAnyMedicationOnDate(DateTime date) {
    return _medicationsForDate(date).isNotEmpty;
  }

  String _medicationDoseKey(
      MedicationItem medication, DateTime date, int doseIndex) {
    final iso = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '${medication.name}_${iso}_$doseIndex';
  }

  bool _isTaken(MedicationItem medication, DateTime date, int doseIndex) {
    return _takenMedications.contains(
      _medicationDoseKey(medication, date, doseIndex),
    );
  }

  DateTime _doseDateTime(MedicationItem medication, DateTime date, int doseIndex) {
    final intervalHours =
        medication.dosesPerDay > 1 ? 24 ~/ medication.dosesPerDay : 0;
    final baseHour = medication.time.hour;
    final baseMinute = medication.time.minute;
    final doseHour = (baseHour + intervalHours * doseIndex) % 24;
    return DateTime(date.year, date.month, date.day, doseHour, baseMinute);
  }

  // PATCH يدوي بدون تعديل api_service.dart (الـ ApiService الحالي ما فيه patch)
  Future<Map<String, dynamic>> _patchJson(
    String path, {
    required Map<String, dynamic> body,
    required String token,
  }) async {
    final response = await http.patch(
      Uri.parse(ApiService.buildUrl(path)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  Future<void> _toggleTaken(
      MedicationItem medication, DateTime date, int doseIndex) async {
    final key = _medicationDoseKey(medication, date, doseIndex);
    final wasTaken = _takenMedications.contains(key);

    setState(() {
      if (wasTaken) {
        _takenMedications.remove(key);
      } else {
        _takenMedications.add(key);
      }
    });
    await _saveTakenMedications();

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.accessToken;
    final medId = int.tryParse(medication.id);
    if (token == null || medId == null) return; // بدون تسجيل دخول: محلي بس

    final scheduledTime =
        _doseDateTime(medication, date, doseIndex).toIso8601String();

    try {
      final existingId = _doseRecordIds[key];
      if (!wasTaken) {
        // صارت مأخوذة الحين
        if (existingId != null) {
          await _patchJson(
            '/dose-logs/$existingId',
            body: {
              'status': 'TAKEN',
              'dose_taken': true,
              'taken_time': DateTime.now().toIso8601String(),
            },
            token: token,
          );
        } else {
          final created = await ApiService.postJson(
            '/dose-logs',
            body: {
              'medication_id': medId,
              'scheduled_time': scheduledTime,
              'status': 'TAKEN',
              'dose_taken': true,
              'taken_time': DateTime.now().toIso8601String(),
            },
            token: token,
          );
          final newId = created['id'];
          if (newId != null) {
            _doseRecordIds[key] =
                newId is int ? newId : int.tryParse(newId.toString()) ?? -1;
          }
        }
      } else if (existingId != null) {
        // كانت مأخوذة وألغيناها
        await _patchJson(
          '/dose-logs/$existingId',
          body: {'status': 'PENDING', 'dose_taken': false},
          token: token,
        );
      }
    } catch (e) {
      debugPrint('Error syncing dose record: $e');
    }
  }

  Future<void> _loadDoseRecords() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.accessToken;
    if (token == null) return;

    try {
      final records = await ApiService.getJsonList('/dose-logs', token: token);

      final taken = <String>{};
      final ids = <String, int>{};

      for (final r in records) {
        final status = (r['status'] ?? '').toString();
        final doseTaken = r['dose_taken'] == true;
        if (status != 'TAKEN' && !doseTaken) continue;

        final medIdRaw = r['medication_id'];
        final scheduledRaw = r['scheduled_time'];
        if (medIdRaw == null || scheduledRaw == null) continue;

        final scheduled = DateTime.tryParse(scheduledRaw.toString());
        if (scheduled == null) continue;

        MedicationItem? med;
        for (final m in _medications) {
          if (m.id == medIdRaw.toString()) {
            med = m;
            break;
          }
        }
        if (med == null) continue;

        int doseIndex = 0;
        for (int i = 0; i < med.dosesPerDay; i++) {
          if (_doseDateTime(med, scheduled, i).hour == scheduled.hour) {
            doseIndex = i;
            break;
          }
        }

        final key = _medicationDoseKey(med, scheduled, doseIndex);
        taken.add(key);

        final recordId = r['id'];
        if (recordId != null) {
          ids[key] =
              recordId is int ? recordId : int.tryParse(recordId.toString()) ?? -1;
        }
      }

      if (!mounted) return;
      setState(() {
        _takenMedications
          ..clear()
          ..addAll(taken);
        _doseRecordIds
          ..clear()
          ..addAll(ids);
      });
    } catch (e) {
      debugPrint('Error loading dose records: $e');
    }
  }

  // ملخص متابعة الجرعات (يستخدم GET /adherence/rate الجاهز بالباك إند)
  void _showAdherenceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<dynamic>(
              future: () async {
                final authProvider = context.read<AuthProvider>();
                final token = authProvider.accessToken;
                if (token == null) return null;
                return ApiService.getJsonDynamic('/adherence/rate', token: token);
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data;
                if (data == null || data is! Map) {
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'تعذر جلب بيانات متابعة الجرعات',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final rate = data['adherence_rate'] ?? 0;
                final completed = data['completed'] ?? 0;
                final total = data['total'] ?? 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'متابعة الجرعات',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$rate%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _Colors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'نسبة الالتزام بالجرعات',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _Colors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('$completed',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('جرعات مأخوذة',
                                style: TextStyle(color: _Colors.textSecondary)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('$total',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('إجمالي الجرعات',
                                style: TextStyle(color: _Colors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _medications.map((m) {
      return {
        'id': m.id,
        'name': m.name,
        'dosage': m.dosage,
        'type': m.type.index,
        'daysOfWeek': m.daysOfWeek,
        'period': m.period,
        'time': {
          'hour': m.time.hour,
          'minute': m.time.minute,
        },
        'dosesPerDay': m.dosesPerDay,
        'reminderEnabled': m.reminderEnabled,
        'isActive': m.isActive,
      };
    }).toList();
    await prefs.setString('medications', jsonEncode(data));
  }

  Future<void> _loadMedications() async {
    final depProvider = context.read<DependentProvider>();
    final authProvider = context.read<AuthProvider>();
    final selectedDep = depProvider.selectedDependent;

    if (authProvider.accessToken == null) return;

    try {
      final token = authProvider.accessToken!;
      final depService = context.read<DependentService>();

      List<dynamic> rawList;

      // أدوية التابع
      if (selectedDep != null) {
        rawList = await depService.getDependentMedications(
          token,
          selectedDep.id,
        );
      }

      // أدوية المستخدم الأساسي
      else {
        rawList = await ApiService.getJsonList(
          '/medications',
          token: token,
        );
      }

      setState(() {
        _medications.clear();

        _medications.addAll(
          rawList.map((m) {
            TimeOfDay time;

            if (m['time'] != null) {
              final parts = m['time'].toString().split(':');

              time = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            } else {
              time = const TimeOfDay(hour: 8, minute: 0);
            }

            return MedicationItem(
              id: m['id'].toString(),
              name: m['name'] ?? '',
              dosage: m['dosage'] ?? '',
              type: MedicationType.values[
                  (m['type'] ?? 0).clamp(0, MedicationType.values.length - 1)],
              daysOfWeek: m['days_of_week'] != null
                  ? List<String>.from(m['days_of_week'])
                  : [],
              period: m['period'] ?? 'صباحا',
              time: time,
              dosesPerDay: m['dosesPerDay'] ?? 1,
              reminderEnabled: true,
              isActive: m['is_active'] ?? true,
            );
          }).toList(),
        );
      });

      await _loadDoseRecords();
    } catch (e) {
      debugPrint("LOAD MEDICATION ERROR = $e");
    }
  }

  Future<void> _saveTakenMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('takenMedications', _takenMedications.toList());
  }

  Future<void> _loadTakenMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList('takenMedications');
    if (saved != null) {
      setState(() {
        _takenMedications
          ..clear()
          ..addAll(saved);
      });
    }
  }

  String _doseTimeLabel(MedicationItem medication, int doseIndex) {
    final intervalHours = medication.dosesPerDay > 1
        ? 24 ~/ medication.dosesPerDay
        : 0;
    final baseHour = medication.time.hour;
    final baseMinute = medication.time.minute;
    final doseHour = (baseHour + intervalHours * doseIndex) % 24;
    final doseTime = TimeOfDay(hour: doseHour, minute: baseMinute);

    final hour = doseTime.hour.toString().padLeft(2, '0');
    final minute = doseTime.minute.toString().padLeft(2, '0');
    final label = _dosePeriodLabel(doseTime);
    return '$hour:$minute $label';
  }

  String _dosePeriodLabel(TimeOfDay time) {
    final hour = time.hour;
    if (hour == 0) return 'منتصف الليل';
    if (hour < 12) return 'صباحاً';
    if (hour == 12) return 'ظهراً';
    if (hour < 18) return 'مساءً';
    return 'مساءً';
  }

  void _openAddMedicationSheet({MedicationItem? existingMedication}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedicationSheet(
        existingMedication: existingMedication,
        onSave: (med) async {
          final depProvider = context.read<DependentProvider>();
          final authProvider = context.read<AuthProvider>();
          final selectedDep = depProvider.selectedDependent;

          if (existingMedication != null) {
            // Update existing medication
            if (authProvider.accessToken != null) {
              try {
                await ApiService.putJson(
                  '/medications/${existingMedication.id}',
                  body: {
                    'name': med.name,
                    'dosage': med.dosage,
                    'type': med.type.index,
                    'days_of_week': med.daysOfWeek,
                    'period': med.period,
                    'time': '${med.time.hour}:${med.time.minute}',
                    'doses_per_day': med.dosesPerDay,
                  },
                  token: authProvider.accessToken!,
                );
                await _loadMedications();
              } catch (e) {
                debugPrint('Error updating medication: $e');
              }
            }
          } else {
            // Add new medication
            if (selectedDep != null && authProvider.accessToken != null) {
              // Save to API for dependent
              try {
                await ApiService.postJson(
                  '/medications',
                  body: {
                    'dependent_id': int.parse(selectedDep.id.toString()),
                    'name': med.name,
                    'dosage': med.dosage,
                    'type': med.type.index,
                    'days_of_week': med.daysOfWeek,
                    'period': med.period,
                    'time': '${med.time.hour}:${med.time.minute}',
                    'doses_per_day': med.dosesPerDay,
                  },
                  token: authProvider.accessToken!,
                );
                await _loadMedications();
              } catch (e) {
                debugPrint('Error saving medication for dependent: $e');
              }
            } else if (authProvider.accessToken != null) {
              try {
                await ApiService.postJson(
                  '/medications',
                  body: {
                    'name': med.name,
                    'dosage': med.dosage,
                    'type': med.type.index,
                    'days_of_week': med.daysOfWeek,
                    'period': med.period,
                    'time': '${med.time.hour}:${med.time.minute}',
                    'doses_per_day': med.dosesPerDay,
                  },
                  token: authProvider.accessToken!,
                );
                await _loadMedications();
              } catch (e) {
                debugPrint(e.toString());
              }
            }
          }
        },
      ),
    );
  }

 Future<void> _deleteMedication(MedicationItem med) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("حذف الدواء"),
      content: Text("هل تريد حذف ${med.name} ؟"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("إلغاء"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text("حذف"),
        ),
      ],
    ),
  );

  if (ok != true) return;

  final auth = context.read<AuthProvider>();
  if (auth.accessToken == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تسجيل الدخول أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
  }

  // قائمة المسارات المحتملة
  final List<Map<String, String>> tests = [
    {'method': 'DELETE', 'path': '/medications/${med.id}'},
    {'method': 'DELETE', 'path': '/medication/${med.id}'},
    {'method': 'DELETE', 'path': '/medicines/${med.id}'},
    {'method': 'DELETE', 'path': '/medicine/${med.id}'},
    {'method': 'DELETE', 'path': '/api/medications/${med.id}'},
    {'method': 'POST', 'path': '/medications/${med.id}', 'body': '{"_method":"DELETE"}'},
    {'method': 'POST', 'path': '/medication/${med.id}', 'body': '{"_method":"DELETE"}'},
    {'method': 'DELETE', 'path': '/medications/delete/${med.id}'},
    {'method': 'DELETE', 'path': '/delete-medication/${med.id}'},
  ];

  String? workingPath;
  int? lastStatusCode;

  for (final test in tests) {
    try {
      final url = ApiService.buildUrl(test['path']!);
      debugPrint('🔍 Trying: ${test['method']} $url');

      http.Response response;

      if (test['method'] == 'POST') {
        response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${auth.accessToken!}',
          },
          body: test['body'],
        );
      } else {
        response = await http.delete(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${auth.accessToken!}',
          },
        );
      }

      debugPrint('🔍 Status: ${response.statusCode} for ${test['path']}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        workingPath = test['path'];
        break;
      } else {
        lastStatusCode = response.statusCode;
      }
    } catch (e) {
      debugPrint('❌ Error with ${test['path']}: $e');
    }
  }

  if (workingPath != null) {
    await _loadMedications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حذف الدواء بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ فشل الحذف: الكود $lastStatusCode'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

  Future<void> _signOut(BuildContext context) async {
    // Clear whatever kind of session is active (email token or Google).
    await AuthRepository().clearSession();
    await GoogleAuthService().signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  // ------------------------- Top bar -------------------------
  Widget _buildTopBar() {
    final hasName =
        widget.userName != null && widget.userName!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting + Profile avatar (rendered on the right in RTL)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Profile avatar - dark green. Tap opens the account menu
                // with improved items: حسابي, الإعدادات, تذكيراتي, أدويتي, التابعون, تسجيل الخروج
                Consumer<DependentProvider>(
                  builder: (context, depProvider, _) {
                    final selectedDep = depProvider.selectedDependent;
                    return PopupMenuButton<String>(
                      tooltip: '',
                      offset: const Offset(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      itemBuilder: (context) => [
                        // Header
                        const PopupMenuItem<String>(
                          enabled: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              ' حسابي',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _Colors.darkGreen,
                              ),
                            ),
                          ),
                        ),
                        const PopupMenuDivider(height: 8),
                        // حسابي
                        const PopupMenuItem<String>(
                          value: 'my_account',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('حسابي', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 12),
                              Icon(Icons.person_outline_rounded, color: _Colors.darkGreen, size: 24),
                            ],
                          ),
                        ),
                        // الإعدادات
                        const PopupMenuItem<String>(
                          value: 'settings',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('الإعدادات', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 12),
                              Icon(Icons.settings_outlined, color: _Colors.darkGreen, size: 24),
                            ],
                          ),
                        ),
                        // تذكيراتي
                        const PopupMenuItem<String>(
                          value: 'reminders',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('تذكيراتي', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 12),
                              Icon(Icons.notifications_outlined, color: _Colors.darkGreen, size: 24),
                            ],
                          ),
                        ),
                        // أدويتي
                        const PopupMenuItem<String>(
                          value: 'my_meds',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('أدويتي', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 12),
                              Icon(Icons.medication_outlined, color: _Colors.darkGreen, size: 24),
                            ],
                          ),
                        ),
                        // متابعة الجرعات
                        const PopupMenuItem<String>(
                          value: 'adherence',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('متابعة الجرعات', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 12),
                              Icon(Icons.fact_check_outlined, color: _Colors.darkGreen, size: 24),
                            ],
                          ),
                        ),
                        // التابعون
                        const PopupMenuItem<String>(
                          value: 'dependents',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('التابعون', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 12),
                              Icon(Icons.people_outline_rounded, color: _Colors.darkGreen, size: 24),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 8),
                        // تسجيل الخروج
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('تسجيل الخروج',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.redAccent,
                                  )),
                              SizedBox(width: 12),
                              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'my_account') {
                          // TODO: Navigate to account screen
                        } else if (value == 'settings') {
                          // TODO: Navigate to settings screen
                        } else if (value == 'reminders') {
                          setState(() => _selectedIndex = 2);
                        } else if (value == 'my_meds') {
                          setState(() => _selectedIndex = 1);
                        } else if (value == 'adherence') {
                          _showAdherenceSheet(context);
                        } else if (value == 'dependents') {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DependentsScreen(),
                            ),
                          );
                          if (changed == true) {
                            _loadMedications();
                          }
                        } else if (value == 'logout') {
                          await _signOut(context);
                        }
                      },
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: selectedDep != null ? const Color(0xFFC9932E) : _Colors.darkGreen,
                        child: selectedDep != null
                            ? Text(selectedDep.fullName[0], style: const TextStyle(color: Colors.white, fontSize: 24))
                            : const Icon(Icons.person, color: Colors.white, size: 38),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Single source for the greeting/name/dependent-profile block.
                Expanded(
                  child: Consumer<DependentProvider>(
                    builder: (context, depProvider, _) {
                      final selectedDep = depProvider.selectedDependent;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedDep != null
                                ? 'ملف: ${selectedDep.fullName}'
                                : (hasName ? '${_getGreeting()}،' : _getGreeting()),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: selectedDep != null ? FontWeight.bold : FontWeight.normal,
                              color: selectedDep != null
                                  ? const Color.fromARGB(255, 8, 78, 3)
                                  : _Colors.textSecondary,
                            ),
                          ),
                          if (selectedDep == null && hasName) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.userName!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _Colors.textPrimary,
                              ),
                            ),
                          ],
                          if (selectedDep != null) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                depProvider.selectDependent(null);
                                _loadMedications();
                              },
                              child: const Text(
                                'العودة لملفي الشخصي',
                                style: TextStyle(
                                  color: _Colors.primaryGreen,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // "+" add button on the left side (rendered on the left in RTL)
          if (_selectedIndex == 1)
            GestureDetector(
              onTap: () => _openAddMedicationSheet(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _Colors.primaryGreen, width: 1.5),
                ),
                child: const Icon(
                  Icons.add,
                  color: _Colors.primaryGreen,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------- Day strip (fixed) -------------------------
  Widget _buildDateStrip() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _dateStrip.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _dateStrip[index];
          final selected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final hasMed = _hasAnyMedicationOnDate(date);
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _Colors.darkGreen : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? _Colors.darkGreen : _Colors.borderGrey,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _arabicDigits(date.day.toString()),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: selected ? Colors.white : _Colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weekdayNameFromDate(date),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : _Colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasMed)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D9E75),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------- Tabs -------------------------
  Widget _buildTodayTab() {
    final todaysMeds = _medicationsForDate(_selectedDate);
    return Column(
      children: [
        _buildDateStrip(),
        const SizedBox(height: 24),
        Expanded(
          child: todaysMeds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF1D9E75),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'لا توجد أدوية مجدولة لهذا اليوم',
                              style: TextStyle(
                                color: Color(0xFF085041),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _openAddMedicationSheet(),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF085041),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: const Text(
                            '+ إضافة دواء',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: todaysMeds.length,
                        itemBuilder: (context, index) =>
                            _MedicationCard(
                              medication: todaysMeds[index],
                              onEdit: () => _openAddMedicationSheet(
                                existingMedication: todaysMeds[index],
                              ),
                              onDelete: () => _deleteMedication(todaysMeds[index]),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _openAddMedicationSheet(),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF085041),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text(
                          '+ إضافة دواء',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMedicationsTab() {
    final active = _medications.where((m) => m.isActive).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _Colors.lightGreenBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'نشطة',
                  style: TextStyle(color: _Colors.darkGreen),
                ),
              ),
              const Spacer(),
              const Text(
                'الأدوية المحفوظة',
                style: TextStyle(color: _Colors.textPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: active.isEmpty
              ? const Center(
                  child: Text(
                    'لا يوجد أدوية محفوظة بعد',
                    style: TextStyle(color: _Colors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: active.length, // unlimited
                  itemBuilder: (context, index) =>
                      _MedicationCard(
                        medication: active[index],
                        onEdit: () => _openAddMedicationSheet(
                          existingMedication: active[index],
                        ),
                        onDelete: () => _deleteMedication(active[index]),
                      ),
                ),
        ),
      ],
    );
  }

  Widget _buildRemindersTab() {
    final selectedMeds = _medicationsForDate(_selectedDate);
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Column(
      children: [
        _buildDateStrip(),
        const SizedBox(height: 24),
        Expanded(
          child: selectedMeds.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'لا توجد أدوية مجدولة لهذا اليوم.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _Colors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: selectedMeds.length,
                  itemBuilder: (context, index) {
                    final medication = selectedMeds[index];
                    return _buildReminderMedicationCard(medication, isToday);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReminderMedicationCard(MedicationItem medication, bool isToday) {
    final checkboxBorder = Border.all(color: const Color(0xFFB85C5C), width: 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Colors.darkGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medication.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            medication.dosage,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...List.generate(medication.dosesPerDay, (doseIndex) {
            final taken = _isTaken(medication, _selectedDate, doseIndex);
            final label = _doseTimeLabel(medication, doseIndex);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: isToday
                        ? () => _toggleTaken(medication, _selectedDate, doseIndex)
                        : null,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: taken ? const Color(0xFFB85C5C) : Colors.transparent,
                        border: checkboxBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: taken
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildTodayTab(),
      _buildMedicationsTab(),
      _buildRemindersTab(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              Expanded(child: tabs[_selectedIndex]),
            ],
          ),
        ),
        floatingActionButton: null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color.fromARGB(255, 4, 96, 67),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar),
              label: 'اليوم',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication),
              label: 'أدويتي',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.bell),
              label: 'التذكيرات',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Medication card (used in both tabs)
// ---------------------------------------------------------------------
class _MedicationCard extends StatelessWidget {
  final MedicationItem medication;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MedicationCard({
    required this.medication,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Colors.darkGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == "edit") {
                onEdit?.call();
              }
              if (value == "delete") {
                onDelete?.call();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: "edit",
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.green),
                    SizedBox(width: 8),
                    Text("تعديل"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "delete",
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text("حذف"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(medication.type.icon, color: _Colors.darkGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${medication.name}${medication.dosage.isNotEmpty ? " ${medication.dosage}" : ""}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medication.timeLabel}. x${medication.dosesPerDay}/اليوم',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Add medication bottom sheet
// ---------------------------------------------------------------------
class _AddMedicationSheet extends StatefulWidget {
  final MedicationItem? existingMedication;
  final void Function(MedicationItem medication) onSave;

  const _AddMedicationSheet({
    this.existingMedication,
    required this.onSave,
  });

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  MedicationType _selectedType = MedicationType.tablets;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _reminderEnabled = true;

  static const List<String> _allDays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  final Set<String> _selectedDays = {};

  String _period = 'صباحا';
  TimeOfDay _time = const TimeOfDay(hour: 6, minute: 0);
  int _dosesPerDay = 1;

  List<Map<String, dynamic>> _pharmacySuggestions = [];

  Future<void> _searchMedicines(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _pharmacySuggestions.clear();
      });
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      final result = await ApiService.getJsonList(
        '/medicines/search?q=$query',
        token: auth.accessToken!,
      );

      setState(() {
        _pharmacySuggestions = List<Map<String, dynamic>>.from(result);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existingMedication;
    if (existing != null) {
      _nameController.text = existing.name;
      _dosageController.text = existing.dosage;
      _selectedType = existing.type;
      _selectedDays.addAll(existing.daysOfWeek);
      _period = existing.period;
      _time = existing.time;
      _dosesPerDay = existing.dosesPerDay;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    setState(() {
      final nameEn = (suggestion['name_en'] ?? '').toString();
      final nameAr = (suggestion['name_ar'] ?? '').toString();

      // نحفظ الاسمين مع بعض بنفس الحقل عشان ما نحتاج نعدل قاعدة البيانات
      _nameController.text =
          nameAr.isNotEmpty ? '$nameEn — $nameAr' : nameEn;

      _dosageController.text =
          suggestion['dosage'] ?? '';

      _searchController.clear();
      _pharmacySuggestions.clear();
    });

    FocusScope.of(context).unfocus();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty && _selectedDays.isNotEmpty;

  void _save({required bool withReminder}) {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الدواء واختيار الأيام')),
      );
      return;
    }

    widget.onSave(
      MedicationItem(
        id: widget.existingMedication?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        type: _selectedType,
        daysOfWeek: _selectedDays.toList(),
        period: _period,
        time: _time,
        dosesPerDay: _dosesPerDay,
        reminderEnabled: withReminder,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _Colors.borderGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'جدول دوائك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _Colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'حدد نوع الدواء:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: _Colors.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    itemCount: MedicationType.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final type = MedicationType.values[index];
                      final selected = type == _selectedType;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: selected ? _Colors.darkGreen : Colors.white,
                            border: Border.all(
                              color: selected
                                  ? _Colors.darkGreen
                                  : _Colors.borderGrey,
                              width: selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            type.icon,
                            color: selected ? Colors.white : _Colors.darkGreen,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'اسم الدواء',
                    style: TextStyle(color: _Colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _searchController,
                  onChanged: _searchMedicines,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن الدواء من نفس الصيدلية',
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_pharmacySuggestions.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FFF9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _Colors.borderGrey),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pharmacySuggestions.length,
                      itemBuilder: (context, index) {
                        final item = _pharmacySuggestions[index];
                        final nameEn = (item['name_en'] ?? '').toString();
                        final nameAr = (item['name_ar'] ?? '').toString();

                        return ListTile(
                          title: Text(
                            nameAr.isNotEmpty ? '$nameEn — $nameAr' : nameEn,
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Text(
                            item['dosage'] ?? '',
                            textAlign: TextAlign.right,
                          ),
                          trailing: const Icon(
                            Icons.medical_services_outlined,
                            color: _Colors.primaryGreen,
                          ),
                          onTap: () => _selectSuggestion(item),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'مثال: Eltroxin',
                          filled: true,
                          fillColor: const Color(0xFFF6F6F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _dosageController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: '100mcg',
                          filled: true,
                          fillColor: const Color(0xFFF6F6F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    itemCount: _allDays.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = _allDays[index];
                      final selected = _selectedDays.contains(day);
                      return GestureDetector(
                        onTap: () => setState(() {
                          selected
                              ? _selectedDays.remove(day)
                              : _selectedDays.add(day);
                        }),
                        child: Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? _Colors.darkGreen : Colors.white,
                            border: Border.all(
                              color: selected
                                  ? _Colors.darkGreen
                                  : _Colors.borderGrey,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white
                                      : _Colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 14,
                                color: selected
                                    ? Colors.white
                                    : _Colors.borderGrey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'الفترة',
                            style: TextStyle(color: _Colors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _period,
                            alignment: AlignmentDirectional.centerEnd,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF6F6F6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'صباحا',
                                child: Text('صباحا'),
                              ),
                              DropdownMenuItem(
                                value: 'مساء',
                                child: Text('مساء'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _period = value!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'الوقت',
                            style: TextStyle(color: _Colors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _time.format(context),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'عدد الجرعات في اليوم',
                    style: TextStyle(color: _Colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(4, (i) {
                    final value = i + 1;
                    final selected = _dosesPerDay == value;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _dosesPerDay = value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _Colors.mutedGreen
                                  : _Colors.darkGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'x$value',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _save(withReminder: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Colors.darkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'حفظ',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _save(withReminder: false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _Colors.darkGreen, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'حفظ الدواء بدون التنبيه',
                      style: TextStyle(color: _Colors.darkGreen, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
