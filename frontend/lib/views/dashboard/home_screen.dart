// lib/views/dashboard/home_screen.dart
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
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/onboarding_screen.dart';
import '../../repositories/auth_repository.dart';
import '../../services/google_auth_service.dart';
import 'package:provider/provider.dart';
import '../../providers/dependent_provider.dart';
import 'dependents_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/dependent_service.dart';
import '../../services/api_service.dart';

// Colors (inlined here to keep this a single self-contained file)
class _Colors {
  static const Color primaryGreen = Color(0xFF1D9E75);
  static const Color darkGreen = Color(0xFF085041);
  static const Color lightGreenBg = Color(0xFFD9F2E7);
  static const Color mutedGreen = Color(0xFF7FBF9E);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black54;
  static const Color borderGrey = Color(0xFFE0E0E0);
}

// Medication model (local, in-memory)
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

// HomeScreen (public API kept identical to the original file)
class HomeScreen extends StatefulWidget {
  final String? userName;
  final String? photoUrl;

  const HomeScreen({super.key, this.userName, this.photoUrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<MedicationItem> _medications = [];
  final Set<String> _takenMedications = {};

  final List<Map<String, dynamic>> _interactionResults = [];

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
    _dateStrip = List.generate(7, (i) => today.add(Duration(days: i - 3)));
    _loadMedications();
    _loadTakenMedications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMedications();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
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

  // (Taken) مطلوب: خانة واحدة لكل دواء خلال اليوم المختار.
  String _medicationTakenKey(MedicationItem medication, DateTime date) {
    final iso = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '${medication.name}_$iso';
  }

  bool _isMedicationTaken(MedicationItem medication, DateTime date) {
    return _takenMedications.contains(_medicationTakenKey(medication, date));
  }

  void _toggleMedicationTaken(MedicationItem medication, DateTime date) {
    final key = _medicationTakenKey(medication, date);
    setState(() {
      if (_takenMedications.contains(key)) {
        _takenMedications.remove(key);
      } else {
        _takenMedications.add(key);
      }
    });
    _saveTakenMedications();
  }

  // Old per-dose methods kept for reminders tab (currently not used after UI change).
  bool _isTaken(MedicationItem medication, DateTime date, int doseIndex) {
    return _takenMedications
        .contains(_medicationDoseKey(medication, date, doseIndex));
  }

  void _toggleTaken(MedicationItem medication, DateTime date, int doseIndex) {
    final key = _medicationDoseKey(medication, date, doseIndex);
    setState(() {
      if (_takenMedications.contains(key)) {
        _takenMedications.remove(key);
      } else {
        _takenMedications.add(key);
      }
    });
    _saveTakenMedications();
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
    final intervalHours =
        medication.dosesPerDay > 1 ? 24 ~/ medication.dosesPerDay : 0;
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
        'time': {'hour': m.time.hour, 'minute': m.time.minute},
        'dosesPerDay': m.dosesPerDay,
        'reminderEnabled': m.reminderEnabled,
        'isActive': m.isActive,
      };
    }).toList();
    await prefs.setString('medications', jsonEncode(data));
  }

  Future<void> _loadMedications() async {
    final authProvider = context.read<AuthProvider>();

    // Requirement: allow delete/add UI even without login.
    // - If token exists: load from backend
    // - Else: load from local SharedPreferences
    if (authProvider.accessToken == null) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('medications');
      if (raw == null || raw.isEmpty) {
        setState(() => _medications.clear());
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        setState(() {
          _medications.clear();
          _medications.addAll(decoded.map((m) {
            final timeMap = Map<String, dynamic>.from(m['time'] as Map);
            return MedicationItem(
              id: (m['id'] ?? '').toString(),
              name: (m['name'] ?? '').toString(),
              dosage: (m['dosage'] ?? '').toString(),
              type: MedicationType.values[m['type'] as int? ?? 0],
              daysOfWeek: List<String>.from(m['daysOfWeek'] ?? const []),
              period: (m['period'] ?? 'صباحا').toString(),
              time: TimeOfDay(
                  hour: timeMap['hour'] as int,
                  minute: timeMap['minute'] as int),
              dosesPerDay: (m['dosesPerDay'] as int?) ?? 1,
              reminderEnabled: (m['reminderEnabled'] as bool?) ?? true,
              isActive: (m['isActive'] as bool?) ?? true,
            );
          }));
        });
      }
      return;
    }

    try {
      final token = authProvider.accessToken!;
      final rawList =
          await ApiService.getJsonList('/medications', token: token);

      if (!mounted) return;

      setState(() {
        _medications.clear();
        _medications.addAll(rawList.map((m) {
          final isApiTime = m['time'] is String;
          TimeOfDay time;
          if (isApiTime) {
            final parts = (m['time'] as String).split(':');
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
            time = TimeOfDay(hour: hour, minute: minute);
          } else {
            final timeMap = Map<String, dynamic>.from(m['time'] as Map);
            final hour = timeMap['hour'];
            final minute = timeMap['minute'];
            time = TimeOfDay(
                hour: (hour is int ? hour : int.tryParse(hour.toString()) ?? 0),
                minute: (minute is int
                    ? minute
                    : int.tryParse(minute.toString()) ?? 0));
          }

          final dynamic rawId = (m['id'] ?? m['medication_id'] ?? m['medId']);

          return MedicationItem(
            id: rawId == null ? '' : rawId.toString(),
            name: (m['name'] ?? '').toString(),
            dosage: m['dosage'] as String? ?? '',
            type: MedicationType.values[m['type'] is int ? m['type'] : 0],
            daysOfWeek: () {
              final rawDays = (m['days_of_week'] is List)
                  ? List<String>.from(m['days_of_week'] as List)
                  : ((m['daysOfWeek'] is List)
                      ? List<String>.from(m['daysOfWeek'] as List)
                      : <String>[]);

              // Backend may return English day names; map them to Arabic.
              const enToAr = <String, String>{
                'Monday': 'الاثنين',
                'Tuesday': 'الثلاثاء',
                'Wednesday': 'الأربعاء',
                'Thursday': 'الخميس',
                'Friday': 'الجمعة',
                'Saturday': 'السبت',
                'Sunday': 'الأحد',
                'الاثنين': 'الاثنين',
                'الثلاثاء': 'الثلاثاء',
                'الأربعاء': 'الأربعاء',
                'الخميس': 'الخميس',
                'الجمعة': 'الجمعة',
                'السبت': 'السبت',
                'الأحد': 'الأحد',
              };

              return rawDays.map((d) => enToAr[d] ?? d).toList();
            }(),
            period: (m['period'] ?? 'صباحا').toString(),
            time: time,
            dosesPerDay:
                (m['dosesPerDay'] as int?) ?? (m['doses_per_day'] as int?) ?? 1,
            reminderEnabled: m['reminderEnabled'] as bool? ?? true,
            isActive: (m['is_active'] ?? m['isActive'] ?? true) as bool,
          );
        }));
      });
    } catch (e) {
      debugPrint('Error loading medications: $e');
    }
  }

  void _openAddMedicationSheet() {
    _openEditMedicationSheet(null);
  }

  void _openEditMedicationSheet(MedicationItem? medicationOrNull) {
    final MedicationItem? editing = medicationOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedicationSheet(
        initialMedication: editing,
        onSave: (med) async {
          final depProvider = context.read<DependentProvider>();
          final authProvider = context.read<AuthProvider>();
          final selectedDep = depProvider.selectedDependent;

          // EDIT
          if (editing != null) {
            if (selectedDep != null && authProvider.accessToken != null) {
              try {
                await ApiService.putJson(
                  '/medications/${editing.id}',
                  body: {
                    'dependent_id': selectedDep.id,
                    'name': med.name,
                    'dosage': med.dosage,
                    'type': med.type.index,
                    'days_of_week': med.daysOfWeek,
                    'period': med.period,
                    'time': '${med.time.hour}:${med.time.minute}',
                    'dosesPerDay': med.dosesPerDay,
                  },
                  token: authProvider.accessToken!,
                );
                _loadMedications();
              } catch (e) {
                debugPrint('Error updating medication: $e');
              }
            }
            return;
          }

          // ADD
          if (selectedDep != null && authProvider.accessToken != null) {
            try {
              await ApiService.postJson(
                '/medications',
                body: {
                  'dependent_id': selectedDep.id,
                  'name': med.name,
                  'dosage': med.dosage,
                  'type': med.type.index,
                  'days_of_week': med.daysOfWeek,
                  'period': med.period,
                  'time': '${med.time.hour}:${med.time.minute}',
                  'dosesPerDay': med.dosesPerDay,
                },
                token: authProvider.accessToken!,
              );
              _loadMedications();
            } catch (e) {
              debugPrint('Error saving medication for dependent: $e');
            }
          } else {
            // Save locally for self
            setState(() => _medications.add(med));
            _saveMedications();
          }
        },
      ),
    );
  }

  Future<void> _deleteMedication(MedicationItem medication) async {
    final authProvider = context.read<AuthProvider>();

    // If no token -> delete locally
    if (authProvider.accessToken == null) {
      setState(() => _medications.removeWhere((m) => m.id == medication.id));
      await _saveMedications();
      return;
    }

    final token = authProvider.accessToken;
    final medicationId = medication.id.trim();

    if (token == null) return;
    if (medicationId.isEmpty) return;

    final parsedId = int.tryParse(medicationId);
    if (parsedId == null) return;

    try {
      await ApiService.deleteJson('/medications/$parsedId', token: token);
      await _loadMedications();
    } catch (e) {
      debugPrint('Error deleting medication: $e');
    }
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
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DependentsScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: selectedDep != null
                            ? const Color(0xFFC9932E)
                            : _Colors.darkGreen,
                        child: selectedDep != null
                            ? Text(
                                selectedDep.fullName[0],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 24),
                              )
                            : const Icon(Icons.person,
                                color: Colors.white, size: 38),
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
                                : (hasName
                                    ? '${_getGreeting()}،'
                                    : _getGreeting()),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: selectedDep != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
                              onTap: () => depProvider.selectDependent(null),
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
              onTap: _openAddMedicationSheet,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _Colors.primaryGreen, width: 1.5),
                ),
                child: const Icon(Icons.add,
                    color: _Colors.primaryGreen, size: 20),
              ),
            ),
        ],
      ),
    );
  }

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
                    color: selected ? _Colors.darkGreen : _Colors.borderGrey),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _arabicDigits(date.day.toString()),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: selected ? Colors.white : _Colors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weekdayNameFromDate(date),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : _Colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  if (hasMed)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF1D9E75), shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle_outline,
                                color: Color(0xFF1D9E75), size: 20),
                            SizedBox(width: 8),
                            Text('لا توجد أدوية مجدولة لهذا اليوم',
                                style: TextStyle(
                                    color: Color(0xFF085041), fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const DependentsScreen()));
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              color: const Color(0xFF085041),
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: const Text('+ إضافة تابعين',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15)),
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
                        itemBuilder: (context, index) => _MedicationCard(
                          medication: todaysMeds[index],
                          onEdit: () =>
                              _openEditMedicationSheet(todaysMeds[index]),
                          onDelete: () => _deleteMedication(todaysMeds[index]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DependentsScreen()));
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                            color: const Color(0xFF085041),
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text('+ إضافة تابعين',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white, fontSize: 15)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: _Colors.lightGreenBg,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('نشطة',
                    style: TextStyle(color: _Colors.darkGreen)),
              ),
              const Spacer(),
              const Text('الأدوية المحفوظة',
                  style: TextStyle(color: _Colors.textPrimary)),
            ],
          ),
        ),
        Expanded(
          child: active.isEmpty
              ? const Center(
                  child: Text('لا يوجد أدوية محفوظة بعد',
                      style: TextStyle(color: _Colors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: active.length,
                  itemBuilder: (context, index) => _MedicationCard(
                    medication: active[index],
                    onEdit: () => _openEditMedicationSheet(active[index]),
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
                    child: Text('لا توجد أدوية مجدولة لهذا اليوم.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _Colors.textSecondary, fontSize: 16)),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: selectedMeds.length,
                  itemBuilder: (context, index) => _buildReminderMedicationCard(
                      selectedMeds[index], isToday),
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
          color: _Colors.darkGreen, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(medication.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(medication.dosage,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          ...List.generate(medication.dosesPerDay, (doseIndex) {
            final taken = _isTaken(medication, _selectedDate, doseIndex);
            final label = _doseTimeLabel(medication, doseIndex);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  GestureDetector(
                    onTap: isToday
                        ? () =>
                            _toggleTaken(medication, _selectedDate, doseIndex)
                        : null,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: taken
                            ? const Color(0xFFB85C5C)
                            : Colors.transparent,
                        border: checkboxBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: taken
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
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
      _buildRemindersTab()
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
                icon: Icon(CupertinoIcons.calendar), label: 'اليوم'),
            BottomNavigationBarItem(
                icon: Icon(Icons.medication), label: 'أدويتي'),
            BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.bell), label: 'التذكيرات'),
          ],
        ),
      ),
    );
  }
}

// Medication card (used in both tabs)
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
          color: _Colors.darkGreen, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medication.timeLabel}. x${medication.dosesPerDay}/اليوم',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (onEdit != null || onDelete != null)
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: onEdit,
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: onDelete,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Add medication bottom sheet
class _AddMedicationSheet extends StatefulWidget {
  final Future<void> Function(MedicationItem medication) onSave;
  final MedicationItem? initialMedication;

  const _AddMedicationSheet({
    required this.onSave,
    this.initialMedication,
  });

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  MedicationType _selectedType = MedicationType.tablets;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final bool _reminderEnabled = true;

  static const List<String> _allDays = [
    'الجمعة',
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
  ];

  final Set<String> _selectedDays = {};

  String _period = 'صباحا';
  TimeOfDay _time = const TimeOfDay(hour: 6, minute: 0);
  int _dosesPerDay = 1;

  static const List<Map<String, String>> _pharmacySuggestions = [
    {'name': 'Paracetamol', 'dosage': '500mg'},
    {'name': 'Amoxicillin', 'dosage': '250mg'},
    {'name': 'Ibuprofen', 'dosage': '400mg'},
    {'name': 'Metformin', 'dosage': '850mg'},
    {'name': 'Omeprazole', 'dosage': '20mg'},
    {'name': 'Vitamin D', 'dosage': '1000IU'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredSuggestions {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return [];

    return _pharmacySuggestions.where((item) {
      final name = item['name']!.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void _selectSuggestion(Map<String, String> suggestion) {
    setState(() {
      _nameController.text = suggestion['name']!;
      _dosageController.text = suggestion['dosage']!;
      _searchController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty && _selectedDays.isNotEmpty;

  Future<void> _save({required bool withReminder}) async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الدواء واختيار الأيام')),
      );
      return;
    }

    await widget.onSave(
      MedicationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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

    if (mounted) {
      Navigator.of(context).pop();
    }
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
                      color: _Colors.textPrimary),
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
                  child: Text('اسم الدواء',
                      style: TextStyle(color: _Colors.textSecondary)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن الدواء من نفس الصيدلية',
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                if (_filteredSuggestions.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FFF9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _Colors.borderGrey),
                    ),
                    child: Column(
                      children: _filteredSuggestions.map((item) {
                        return ListTile(
                          title:
                              Text(item['name']!, textAlign: TextAlign.right),
                          subtitle:
                              Text(item['dosage']!, textAlign: TextAlign.right),
                          trailing: const Icon(Icons.medical_services_outlined,
                              color: _Colors.primaryGreen),
                          onTap: () => _selectSuggestion(item),
                        );
                      }).toList(),
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
                              borderSide: BorderSide.none),
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
                              borderSide: BorderSide.none),
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
                                    : _Colors.borderGrey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(day,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selected
                                        ? Colors.white
                                        : _Colors.textPrimary,
                                  )),
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
                          const Text('الفترة',
                              style: TextStyle(color: _Colors.textSecondary)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _period,
                            alignment: AlignmentDirectional.centerEnd,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF6F6F6),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'صباحا', child: Text('صباحا')),
                              DropdownMenuItem(
                                  value: 'مساء', child: Text('مساء')),
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
                          const Text('الوقت',
                              style: TextStyle(color: _Colors.textSecondary)),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_time.format(context),
                                  textAlign: TextAlign.center),
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
                  child: Text('عدد الجرعات في اليوم',
                      style: TextStyle(color: _Colors.textSecondary)),
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
                                  fontWeight: FontWeight.bold),
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
                    onPressed: () async => _save(withReminder: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Colors.darkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('حفظ',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async => _save(withReminder: false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: _Colors.darkGreen, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('حفظ الدواء بدون التنبيه',
                        style:
                            TextStyle(color: _Colors.darkGreen, fontSize: 15)),
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
