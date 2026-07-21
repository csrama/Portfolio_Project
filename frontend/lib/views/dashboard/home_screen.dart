import 'dart:convert';
import '../../repositories/auth_repository.dart';
import '../../services/google_auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../models/dependent.dart';
import '../../models/medication_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dependent_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/api_service.dart';
import '../../services/dependent_service.dart';
import '../../services/notification_service.dart';
import '../../services/drug_interaction_service.dart';
import '../../i18n/strings.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/profile_screen.dart';
import 'dependents_screen.dart';
import 'dependent_dashboard_screen.dart';

const Map<String, String> _relationshipLabels = {
  'spouse': 'زوج/زوجة',
  'child': 'ابن/ابنة',
  'parent': 'أب/أم',
  'sibling': 'أخ/أخت',
  'other': 'أخرى',
};

String _relationshipDisplay(String? relationship) {
  if (relationship == null || relationship.isEmpty) return 'لا يوجد';
  return _relationshipLabels[relationship] ?? relationship;
}

String _relationshipValue(String? arabicLabel) {
  if (arabicLabel == null || arabicLabel.isEmpty) return 'other';
  final reversedMap = _relationshipLabels.entries
      .where((e) => e.value == arabicLabel)
      .map((e) => e.key)
      .toList();
  return reversedMap.isNotEmpty ? reversedMap.first : 'other';
}

class _Colors {
  static const Color primaryGreen = Color(0xFF1D9E75);
  static const Color darkGreen = Color(0xFF085041);
  static const Color lightGreenBg = Color(0xFFD9F2E7);
  static const Color mutedGreen = Color(0xFF7FBF9E);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black54;
  static const Color borderGrey = Color(0xFFE0E0E0);
}

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
  final Set<String> _notTakenMedications = {}; // explicit not-taken state
  final Map<String, int> _doseRecordIds = {}; // نفس المفتاح -> id السجل بالباك إند
  List<DrugInteraction> _interactions = []; // تداخلات دوائية بين الأدوية الحالية
  final DrugInteractionService _interactionService = DrugInteractionService();
  bool _interactionsBannerExpanded = false; // مطوي افتراضياً، يفتح بالضغط

  late final List<DateTime> _dateStrip;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = today;
    _dateStrip = List.generate(7, (i) => today.add(Duration(days: i - 3)));
    _loadMedications();
    _loadTakenMedications();
    // Load dependents list for the Today tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.accessToken != null) {
        context.read<DependentProvider>().fetchDependents(auth.accessToken!);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMedications();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'صباح الخير';
    if (hour >= 12 && hour < 17) return 'مساء الخير';
    return 'مساء الخير';
  }

  String _arabicDigits(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return input.split('').map((c) {
      final digit = int.tryParse(c);
      return digit != null ? arabic[digit] : c;
    }).join();
  }

  String _weekdayNameFromDate(DateTime date) {
    final weekday = date.weekday;
    // DateTime.weekday: Monday=1, Tuesday=2, ..., Sunday=7
    const names = [
      'الاثنين',    // Monday (1)
      'الثلاثاء',   // Tuesday (2)
      'الأربعاء',   // Wednesday (3)
      'الخميس',     // Thursday (4)
      'الجمعة',     // Friday (5)
      'السبت',      // Saturday (6)
      'الأحد',      // Sunday (7)
    ];
    return names[weekday - 1];
  }

  List<MedicationItem> _medicationsForDate(DateTime date) {
    final dayName = _weekdayNameFromDate(date);
    return _medications.where((med) {
      final scheduledEveryDay = med.daysOfWeek.isEmpty;
      return med.isActive && (scheduledEveryDay || med.daysOfWeek.contains(dayName));
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

  bool _isNotTaken(MedicationItem medication, DateTime date, int doseIndex) {
    return _notTakenMedications.contains(
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

  Future<void> _updateDoseStatus(
      MedicationItem medication, DateTime date, int doseIndex, bool markTaken) async {
    final key = _medicationDoseKey(medication, date, doseIndex);
    final wasTaken = _takenMedications.contains(key);
    final wasNotTaken = _notTakenMedications.contains(key);
    final willBeTaken = markTaken ? !wasTaken : false;
    final willBeNotTaken = markTaken ? false : !wasNotTaken;

    setState(() {
      if (willBeTaken) {
        _takenMedications.add(key);
        _notTakenMedications.remove(key);
      } else if (willBeNotTaken) {
        _notTakenMedications.add(key);
        _takenMedications.remove(key);
      } else {
        _takenMedications.remove(key);
        _notTakenMedications.remove(key);
      }
    });

    await Future.wait([
      _saveTakenMedications(),
      _saveNotTakenMedications(),
    ]);

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.accessToken;
    final medId = int.tryParse(medication.id);
    if (token == null || medId == null) return;

    final scheduledTime =
        _doseDateTime(medication, date, doseIndex).toIso8601String();

    try {
      final existingId = _doseRecordIds[key];

      if (willBeTaken) {
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
      } else if (willBeNotTaken) {
        if (existingId != null) {
          await _patchJson(
            '/dose-logs/$existingId',
            body: {'status': 'PENDING', 'dose_taken': false},
            token: token,
          );
        } else {
          final created = await ApiService.postJson(
            '/dose-logs',
            body: {
              'medication_id': medId,
              'scheduled_time': scheduledTime,
              'status': 'PENDING',
              'dose_taken': false,
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

      if (selectedDep != null) {
        rawList = await depService.getDependentMedications(
          token,
          selectedDep.id,
        );
      } else {
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
      await _checkAllInteractions();
    } catch (e) {
      debugPrint("LOAD MEDICATION ERROR = $e");
    }
  }

  /// يفحص كل الأدوية الحالية (بعضها ببعض) ويخزّن أي تداخلات موجودة
  /// في _interactions، عشان يعرضها البانر بأعلى الشاشة الرئيسية.
  Future<void> _checkAllInteractions() async {
    if (_medications.length < 2) {
      if (mounted) setState(() => _interactions = []);
      return;
    }
    try {
      final found = await _interactionService
          .checkInteractions(_medications.map((m) => m.name).toList());
      if (mounted) setState(() => _interactions = found);
    } catch (e) {
      debugPrint('Interaction check failed: $e');
    }
  }

  /// يفحص دواء معيّن (بالاسم) مقابل بقية الأدوية الحالية فقط،
  /// يُستخدم لعرض تحذير فوري بعد إضافة دواء جديد.
  Future<List<DrugInteraction>> _checkInteractionsFor(
      String newMedName) async {
    try {
      return await _interactionService.checkNewMedication(
        newMedName,
        _medications.map((m) => m.name).toList(),
      );
    } catch (e) {
      debugPrint('Interaction check failed: $e');
      return [];
    }
  }

  String _severityLabelAr(String severity) {
    switch (severity) {
      case 'contraindicated':
        return 'خطر جداً - يمنع الجمع بينهما';
      case 'major':
        return 'خطورة عالية';
      case 'moderate':
        return 'خطورة متوسطة';
      case 'minor':
        return 'خطورة بسيطة';
      default:
        return severity;
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'contraindicated':
        return const Color(0xFF8B0000);
      case 'major':
        return const Color(0xFFD32F2F);
      case 'moderate':
        return const Color(0xFFF57C00);
      case 'minor':
        return const Color(0xFFFBC02D);
      default:
        return Colors.grey;
    }
  }

  /// يبني نص + لون التفاصيل لتداخل واحد بالعربي (يرجع للإنجليزي لو ما لقى ترجمة).
  Widget _buildInteractionDetailTile(DrugInteraction i,
      {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${i.ingredientAAr} + ${i.ingredientBAr}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: emphasize ? 16 : 14,
            ),
          ),
          Text(
            _severityLabelAr(i.severity),
            style: TextStyle(
              color: _severityColor(i.severity),
              fontWeight: FontWeight.bold,
              fontSize: emphasize ? 13 : 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(i.descriptionAr,
              style: TextStyle(fontSize: emphasize ? 14 : 13)),
          if (i.recommendationAr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'التوصية: ${i.recommendationAr}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  /// يعرض نافذة تفاصيل تداخل (أو أكثر) بالعربي.
  Future<void> _showInteractionDetailsDialog(
      List<DrugInteraction> found) async {
    if (found.isEmpty || !mounted) return;
    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
              SizedBox(width: 8),
              Text('تنبيه: تداخل دوائي'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: found
                  .map((i) => _buildInteractionDetailTile(i, emphasize: true))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('فهمت'),
            ),
          ],
        ),
      ),
    );
  }

  /// يعرض نافذة تحذير فورية لو الدواء المُضاف حديثاً يتعارض مع أدوية موجودة.
  Future<void> _showInteractionWarningIfNeeded(String newMedName) async {
    final found = await _checkInteractionsFor(newMedName);
    await _showInteractionDetailsDialog(found);
  }

  /// بانر قابل للطي بأعلى الشاشة الرئيسية يعرض كل التداخلات الموجودة حالياً.
  /// مطوي افتراضياً (سطر ملخّص واحد)، يفتح بالضغط عليه، وكل عنصر بداخله
  /// قابل للضغط لفتح تفاصيله الكاملة.
  Widget _buildInteractionsBanner() {
    if (_interactions.isEmpty) return const SizedBox.shrink();

    final highest = _interactions.first; // مفروزة مسبقاً من الأخطر للأبسط
    final highestSeverity = highest.severity;
    final counts = <String, int>{};
    for (final i in _interactions) {
      counts[i.severity] = (counts[i.severity] ?? 0) + 1;
    }
    final summaryParts = ['contraindicated', 'major', 'moderate', 'minor']
        .where((s) => counts.containsKey(s))
        .map((s) => '${_arabicDigits(counts[s].toString())} ${_severityLabelAr(s).replaceFirst('خطر جداً - يمنع الجمع بينهما', 'ممنوع')}')
        .join('، ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _severityColor(highestSeverity).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(
                () => _interactionsBannerExpanded = !_interactionsBannerExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: _severityColor(highestSeverity), size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'تداخلات دوائية (${_arabicDigits(_interactions.length.toString())})'
                      '${summaryParts.isNotEmpty ? ' — $summaryParts' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _severityColor(highestSeverity),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    _interactionsBannerExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _severityColor(highestSeverity),
                  ),
                ],
              ),
            ),
          ),
          if (_interactionsBannerExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _interactions.map((i) {
                  final isHighest = i.severity == highestSeverity;
                  return InkWell(
                    onTap: () => _showInteractionDetailsDialog([i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: isHighest ? 10 : 8,
                            height: isHighest ? 10 : 8,
                            decoration: BoxDecoration(
                              color: _severityColor(i.severity),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${i.ingredientAAr} + ${i.ingredientBAr} — ${_severityLabelAr(i.severity)}',
                              style: TextStyle(
                                fontSize: isHighest ? 13 : 12,
                                fontWeight:
                                    isHighest ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded,
                              size: 16, color: Colors.black45),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveTakenMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('takenMedications', _takenMedications.toList());
  }

  Future<void> _saveNotTakenMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notTakenMedications', _notTakenMedications.toList());
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

  Future<void> _loadNotTakenMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList('notTakenMedications');
    if (saved != null) {
      setState(() {
        _notTakenMedications
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
                if (med.reminderEnabled) {
                  final idx = _medications.indexWhere((m) => m.name == med.name && m.time.hour == med.time.hour && m.time.minute == med.time.minute);
                  if (idx >= 0) {
                    await NotificationService.scheduleMedicineReminder(
                      id: idx,
                      medicineName: _medications[idx].name,
                      hour: _medications[idx].time.hour,
                      minute: _medications[idx].time.minute,
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error updating medication: $e');
              }
            }
            // فحص التداخل بعد تحديث دواء موجود (قد يكون الاسم تغيّر)
            await _showInteractionWarningIfNeeded(med.name);
          } else {
            if (selectedDep != null && authProvider.accessToken != null) {
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
                if (med.reminderEnabled) {
                  final idx = _medications.indexWhere((m) => m.name == med.name && m.time.hour == med.time.hour && m.time.minute == med.time.minute);
                  if (idx >= 0) {
                    await NotificationService.scheduleMedicineReminder(
                      id: idx,
                      medicineName: _medications[idx].name,
                      hour: _medications[idx].time.hour,
                      minute: _medications[idx].time.minute,
                    );
                  }
                }
                await _showInteractionWarningIfNeeded(med.name);
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
                if (med.reminderEnabled) {
                  final idx = _medications.indexWhere((m) => m.name == med.name && m.time.hour == med.time.hour && m.time.minute == med.time.minute);
                  if (idx >= 0) {
                    await NotificationService.scheduleMedicineReminder(
                      id: idx,
                      medicineName: _medications[idx].name,
                      hour: _medications[idx].time.hour,
                      minute: _medications[idx].time.minute,
                    );
                  }
                }
                await _showInteractionWarningIfNeeded(med.name);
              } catch (e) {
                debugPrint(e.toString());
              }
            } else {
              setState(() => _medications.add(med));
              await _saveMedications();
              if (med.reminderEnabled) {
                await NotificationService.scheduleMedicineReminder(
                  id: _medications.length - 1,
                  medicineName: med.name,
                  hour: med.time.hour,
                  minute: med.time.minute,
                );
              }
              await _showInteractionWarningIfNeeded(med.name);
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
    await AuthRepository().clearSession();
    await GoogleAuthService().signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  Widget _buildTopBar() {
    final hasName =
        widget.userName != null && widget.userName!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
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
                        } else if (value == 'settings') {
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

  Widget _buildDateStrip() {
    // شريط مرن يمتلئ بعرض الشاشة بنفس هوامش باقي عناصر التصميم (16px)
    // بدل قائمة أفقية بعرض ثابت تترك فراغ على الشاشات الواسعة.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_dateStrip.length, (index) {
          final date = _dateStrip[index];
          final selected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final hasMed = _hasAnyMedicationOnDate(date);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == _dateStrip.length - 1 ? 0 : 6),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
                        overflow: TextOverflow.ellipsis,
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
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTodayTab() {
    final todaysMeds = _medicationsForDate(_selectedDate);
    final depProvider = context.watch<DependentProvider>();
    final dependentsList = depProvider.dependents;

    return Column(
      children: [
        _buildInteractionsBanner(),
        _buildDateStrip(),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // --- Medications Section Links Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _openAddMedicationSheet(),
                    child: const Text(
                      'إضافة دواء',
                      style: TextStyle(
                        color: _Colors.darkGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedIndex = 1);
                    },
                    child: const Text(
                      'عرض المزيد',
                      style: TextStyle(
                        color: _Colors.darkGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // --- Medications Section Title ---
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'الأدوية المضافه',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _Colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // --- Medications List ---
              if (todaysMeds.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFF1D9E75), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'لا توجد أدوية مجدولة لهذا اليوم',
                        style: TextStyle(color: Color(0xFF085041), fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                ...todaysMeds.map((med) => _MedicationCard(
                      medication: med,
                      onEdit: () => _openAddMedicationSheet(existingMedication: med),
                      onDelete: () => _deleteMedication(med),
                    )),
              const SizedBox(height: 16),
              // --- Add Medication Button ---
              GestureDetector(
                onTap: () => _openAddMedicationSheet(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF085041),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '+ إضافة دواء',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Dependents Section Links Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DependentsScreen()),
                      );
                      if (changed == true) _loadMedications();
                    },
                    child: const Text(
                      'إضافة تابعين',
                      style: TextStyle(
                        color: _Colors.darkGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DependentsScreen()),
                      );
                      if (changed == true) _loadMedications();
                    },
                    child: const Text(
                      'عرض المزيد',
                      style: TextStyle(
                        color: _Colors.darkGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // --- Dependents Section Title ---
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'التابعين المضافين',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _Colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // --- Dependents List ---
              if (dependentsList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, color: _Colors.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'لا يوجد تابعين مضافين بعد',
                        style: TextStyle(color: _Colors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                ...dependentsList.map((dep) => _buildDependentCard(dep)),
              const SizedBox(height: 16),
              // --- Add Dependent Button ---
              GestureDetector(
                onTap: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DependentsScreen()),
                  );
                  if (changed == true) _loadMedications();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF085041), width: 1.5),
                  ),
                  child: const Text(
                    '+ إضافة تابع',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF085041),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDependentCard(Dependent dependent) {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DependentDashboardScreen(dependent: dependent),
          ),
        );
        if (changed == true && mounted) {
          final auth = context.read<AuthProvider>();
          if (auth.accessToken != null) {
            context.read<DependentProvider>().fetchDependents(auth.accessToken!);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFC9932E),
              child: Text(
                dependent.fullName.isNotEmpty ? dependent.fullName[0] : '?',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dependent.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _Colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dependent.relationship,
                    style: const TextStyle(color: _Colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: Colors.white,
              icon: const Icon(Icons.more_vert, color: _Colors.textSecondary),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDependentDialog(dependent);
                } else if (value == 'delete') {
                  _confirmDeleteDependent(dependent);
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
          ],
        ),
      ),
    );
  }

  void _showEditDependentDialog(Dependent dependent) {
    final nameController = TextEditingController(text: dependent.fullName);
    String? selectedRelationship = dependent.relationship;

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل بيانات التابع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRelationship,
                decoration: const InputDecoration(
                  labelText: 'صلة القرابة',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'spouse', child: Text('زوج/زوجة')),
                  DropdownMenuItem(value: 'child', child: Text('ابن/ابنة')),
                  DropdownMenuItem(value: 'parent', child: Text('أب/أم')),
                  DropdownMenuItem(value: 'sibling', child: Text('أخ/أخت')),
                  DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                onChanged: (value) => selectedRelationship = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final auth = context.read<AuthProvider>();
                if (auth.accessToken == null) return;
                final success = await context.read<DependentProvider>().updateDependent(
                  auth.accessToken!,
                  dependent.id.toString(),
                  {
                    'full_name': nameController.text.trim(),
                    'relationship': selectedRelationship ?? dependent.relationship,
                  },
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'تم التحديث بنجاح ✅' : 'فشل التحديث'),
                      backgroundColor: success ? const Color(0xFF1D9E75) : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF085041),
              ),
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDependent(Dependent dependent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف التابع'),
          content: Text('هل أنت متأكد من حذف "${dependent.fullName}"؟ لا يمكن التراجع عن هذا الإجراء.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final auth = context.read<AuthProvider>();
      if (auth.accessToken == null) return;
      final success = await context.read<DependentProvider>().deleteDependent(
        auth.accessToken!,
        dependent.id.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم حذف التابع بنجاح 🗑️' : 'فشل الحذف'),
            backgroundColor: success ? const Color(0xFF1D9E75) : Colors.red,
          ),
        );
      }
    }
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
                  itemCount: active.length,
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

  Widget _buildDoseActionRow(
    MedicationItem medication,
    DateTime date,
    int doseIndex,
    bool enabled,
  ) {
    final taken = _isTaken(medication, date, doseIndex);
    final notTaken = _isNotTaken(medication, date, doseIndex);
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
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: ElevatedButton(
                onPressed: enabled
                    ? () => _updateDoseStatus(
                          medication,
                          date,
                          doseIndex,
                          true,
                        )
                    : null,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (taken) {
                      return const Color(0xFF1D9E75);
                    }
                    return const Color(0xFFE1F5EE).withValues(
                      alpha: states.contains(WidgetState.disabled) ? 0.4 : 1.0,
                    );
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (taken) {
                      return Colors.white;
                    }
                    return const Color(0xFF1D9E75).withValues(
                      alpha: states.contains(WidgetState.disabled) ? 0.4 : 1.0,
                    );
                  }),
                  side: WidgetStateProperty.resolveWith((states) {
                    final color = const Color(0xFF1D9E75);
                    return BorderSide(
                      color: states.contains(WidgetState.disabled)
                          ? color.withValues(alpha: 0.4)
                          : color,
                      width: 1.5,
                    );
                  }),
                  minimumSize: WidgetStateProperty.all(const Size.fromHeight(30)),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                child: const Text(
                  'مأخوذة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: ElevatedButton(
                onPressed: enabled
                    ? () => _updateDoseStatus(
                          medication,
                          date,
                          doseIndex,
                          false,
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: notTaken
                      ? const Color(0xFFB85C5C)
                      : Colors.white,
                  foregroundColor: notTaken ? Colors.white : _Colors.darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'لم تُؤخذ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: notTaken ? Colors.white : _Colors.darkGreen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
            return _buildDoseActionRow(medication, _selectedDate, doseIndex, isToday);
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
      const ProfileScreen(),
    ];

    final settings = context.watch<AppSettingsProvider>();
    final isRtl = settings.languageCode == 'ar';
    final textDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedIndex != 3) _buildTopBar(),
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
          items: [
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.calendar),
              label: Strings.tr(context, 'today'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.medication),
              label: Strings.tr(context, 'my_meds'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.bell),
              label: Strings.tr(context, 'reminders'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.person),
              label: Strings.tr(context, 'my_account'),
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
  final bool showDoseActions;
  final DateTime? selectedDate;
  final bool isToday;
  final bool Function(MedicationItem medication, DateTime date, int doseIndex)? isTaken;
  final bool Function(MedicationItem medication, DateTime date, int doseIndex)? isNotTaken;
  final void Function(MedicationItem medication, DateTime date, int doseIndex, bool markTaken)? onUpdateDoseStatus;
  final String Function(MedicationItem medication, int doseIndex)? doseTimeLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MedicationCard({
    required this.medication,
    this.showDoseActions = false,
    this.selectedDate,
    this.isToday = false,
    this.isTaken,
    this.isNotTaken,
    this.onUpdateDoseStatus,
    this.doseTimeLabel,
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
                if (showDoseActions && selectedDate != null && isTaken != null && isNotTaken != null && onUpdateDoseStatus != null) ...[
                  const SizedBox(height: 12),
                  ...List.generate(medication.dosesPerDay, (doseIndex) {
                    final taken = isTaken!(medication, selectedDate!, doseIndex);
                    final notTaken = isNotTaken!(medication, selectedDate!, doseIndex);
                    final doseTime = doseTimeLabel!(medication, doseIndex);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              doseTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(end: 4),
                              child: ElevatedButton(
                                onPressed: isToday
                                    ? () => onUpdateDoseStatus!(
                                          medication,
                                          selectedDate!,
                                          doseIndex,
                                          true,
                                        )
                                    : null,
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith(
                                      (states) {
                                    if (taken) {
                                      return const Color(0xFF1D9E75);
                                    }
                                    return const Color(0xFFE1F5EE).withValues(
                                      alpha: states.contains(WidgetState.disabled)
                                          ? 0.4
                                          : 1.0,
                                    );
                                  }),
                                  foregroundColor: WidgetStateProperty.resolveWith(
                                      (states) {
                                    if (taken) {
                                      return Colors.white;
                                    }
                                    return const Color(0xFF1D9E75).withValues(
                                      alpha: states.contains(WidgetState.disabled)
                                          ? 0.4
                                          : 1.0,
                                    );
                                  }),
                                  side: WidgetStateProperty.resolveWith((states) {
                                    final color = const Color(0xFF1D9E75);
                                    return BorderSide(
                                      color: states.contains(WidgetState.disabled)
                                          ? color.withValues(alpha: 0.4)
                                          : color,
                                      width: 1.5,
                                    );
                                  }),
                                  minimumSize: WidgetStateProperty.all(const Size.fromHeight(30)),
                                  padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                  ),
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'تناولت',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(start: 4),
                              child: ElevatedButton(
                                onPressed: isToday
                                    ? () => onUpdateDoseStatus!(
                                          medication,
                                          selectedDate!,
                                          doseIndex,
                                          false,
                                        )
                                    : null,
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith(
                                      (states) {
                                    if (notTaken) {
                                      return const Color(0xFFB85C5C);
                                    }
                                    return Colors.white.withValues(
                                        alpha: states.contains(WidgetState.disabled)
                                            ? 0.4
                                            : 1.0);
                                  }),
                                  foregroundColor: WidgetStateProperty.resolveWith(
                                      (states) {
                                    if (notTaken) {
                                      return Colors.white;
                                    }
                                    return _Colors.darkGreen.withValues(
                                        alpha: states.contains(WidgetState.disabled)
                                            ? 0.4
                                            : 1.0);
                                  }),
                                  side: WidgetStateProperty.resolveWith((states) {
                                    final color = _Colors.darkGreen;
                                    return BorderSide(
                                      color: states.contains(WidgetState.disabled)
                                          ? color.withValues(alpha: 0.4)
                                          : color,
                                      width: 1.5,
                                    );
                                  }),
                                  minimumSize:
                                      WidgetStateProperty.all(const Size.fromHeight(30)),
                                  padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                  ),
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'لم أتناول',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
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