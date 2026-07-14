import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/dependent_provider.dart';
import '../../models/medication.dart';
import 'dependents_screen.dart';


class _Colors {
  static const Color primaryGreen = Color(0xFF1D9E75);
  static const Color darkGreen = Color(0xFF085041);
  static const Color lightGreenBg = Color(0xFFD9F2E7);
  static const Color mutedGreen = Color(0xFF7FBF9E);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black54;
  static const Color borderGrey = Color(0xFFE0E0E0);
}



enum MedicationType { drops, cream, injection, bottle, tablets, capsule }

extension MedicationTypeIcon on MedicationType {
  IconData get icon {
    switch (this) {
      case MedicationType.drops: return Icons.opacity;
      case MedicationType.cream: return Icons.back_hand_outlined;
      case MedicationType.injection: return Icons.vaccines_outlined;
      case MedicationType.bottle: return Icons.medication_liquid_outlined;
      case MedicationType.tablets: return Icons.grain;
      case MedicationType.capsule: return Icons.medication_outlined;
    }
  }
}

class MedicationUIModel {
  final String id;
  final String name;
  final String dosage;
  final MedicationType type;
  final List<String> daysOfWeek;
  final String period;
  final TimeOfDay time;
  final int dosesPerDay;
  final bool reminderEnabled;
  final bool isActive;

  MedicationUIModel({
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

  factory MedicationUIModel.fromMedication(Medication medication) {
    final timeParts = medication.times.isNotEmpty 
        ? medication.times.first.split(':') 
        : ['06', '00'];
    final hour = int.tryParse(timeParts[0]) ?? 6;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

    final days = medication.daysOfWeek.isEmpty 
        ? ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد']
        : medication.daysOfWeek;

    return MedicationUIModel(
      id: medication.id,
      name: medication.name,
      dosage: medication.dosage,
      type: _mapType(medication.form),
      daysOfWeek: days,
      period: hour >= 12 ? 'مساء' : 'صباحا',
      time: TimeOfDay(hour: hour, minute: minute),
      dosesPerDay: medication.times.length,
      reminderEnabled: true,
      isActive: medication.isActive,
    );
  }

  static MedicationType _mapType(String form) {
    switch (form.toLowerCase()) {
      case 'drops': return MedicationType.drops;
      case 'cream': return MedicationType.cream;
      case 'injection': return MedicationType.injection;
      case 'bottle': return MedicationType.bottle;
      case 'tablet': return MedicationType.tablets;
      case 'capsule': return MedicationType.capsule;
      default: return MedicationType.tablets;
    }
  }

  Medication toMedication(String dependentId) {
    return Medication(
      id: id,
      name: name,
      genericName: name,
      dosage: dosage,
      form: _getFormString(type),
      times: _generateTimes(),
      daysOfWeek: daysOfWeek,
      dependentId: dependentId,
      isActive: isActive,
    );
  }

  String _getFormString(MedicationType type) {
    switch (type) {
      case MedicationType.drops: return 'drops';
      case MedicationType.cream: return 'cream';
      case MedicationType.injection: return 'injection';
      case MedicationType.bottle: return 'bottle';
      case MedicationType.tablets: return 'tablet';
      case MedicationType.capsule: return 'capsule';
    }
  }

  List<String> _generateTimes() {
    final List<String> times = [];
    final baseHour = time.hour;
    final baseMinute = time.minute;
    final intervalHours = dosesPerDay > 1 ? 24 ~/ dosesPerDay : 0;

    for (int i = 0; i < dosesPerDay; i++) {
      final hour = (baseHour + intervalHours * i) % 24;
      times.add('${hour.toString().padLeft(2, '0')}:${baseMinute.toString().padLeft(2, '0')}');
    }
    return times;
  }

  String get timeLabel {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}


class HomeScreen extends StatefulWidget {
  final String? userName;

  const HomeScreen({super.key, this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final Set<String> _takenMedications = {};
  late List<DateTime> _dateStrip;
  late DateTime _selectedDate;

  static const List<String> _weekdayAr = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = today;
    _dateStrip = List.generate(7, (i) => today.add(Duration(days: i - 3)));
    _loadTakenMedications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().loadMedications();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    return hour < 12 ? 'صباح الخير' : 'مساء الخير';
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

  List<MedicationUIModel> _getMedicationsForDate(DateTime date) {
    final medications = context.watch<MedicationProvider>().medications;
    final dayName = _weekdayNameFromDate(date);

    return medications
        .where((med) {
          final isScheduled = med.daysOfWeek.isEmpty || 
              med.daysOfWeek.contains(dayName);
          return med.isActive && isScheduled;
        })
        .map((med) => MedicationUIModel.fromMedication(med))
        .toList();
  }

  bool _hasAnyMedicationOnDate(DateTime date) {
    return _getMedicationsForDate(date).isNotEmpty;
  }

  String _medicationTakenKey(MedicationUIModel medication, DateTime date) {
    final iso = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '${medication.id}_$iso';
  }

  bool _isMedicationTaken(MedicationUIModel medication, DateTime date) {
    return _takenMedications.contains(_medicationTakenKey(medication, date));
  }

  void _toggleMedicationTaken(MedicationUIModel medication, DateTime date) {
    final key = _medicationTakenKey(medication, date);
    setState(() {
      _takenMedications.contains(key) 
          ? _takenMedications.remove(key) 
          : _takenMedications.add(key);
    });
    _saveTakenMedications();
  }

  Future<void> _saveTakenMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('takenMedications', _takenMedications.toList());
  }

  Future<void> _loadTakenMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('takenMedications');
    if (saved != null) {
      setState(() => _takenMedications.addAll(saved));
    }
  }

  void _openAddMedicationSheet() {
    final depProvider = context.read<DependentProvider>();
    final selectedDep = depProvider.selectedDependent;

    if (selectedDep == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار تابع أولاً')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedicationSheet(
        dependentId: selectedDep.id,
        onSave: (uiModel) async {
          final medication = uiModel.toMedication(selectedDep.id);
          final success = await context.read<MedicationProvider>()
              .addMedication(medication);
          
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(' تم إضافة الدواء بنجاح')),
            );
          }
        },
      ),
    );
  }

  void _openEditMedicationSheet(MedicationUIModel uiModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedicationSheet(
        dependentId: context.read<DependentProvider>().selectedDependent?.id ?? '',
        initialMedication: uiModel,
        onSave: (updatedUiModel) async {
          final medication = updatedUiModel.toMedication(
            context.read<DependentProvider>().selectedDependent?.id ?? ''
          );
          final success = await context.read<MedicationProvider>()
              .addMedication(medication);
          
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(' تم تحديث الدواء بنجاح')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteMedication(MedicationUIModel uiModel) async {
    final success = await context.read<MedicationProvider>()
        .deleteMedication(uiModel.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' تم حذف الدواء')),
      );
    }
  }

  Widget _buildTopBar() {
    final authProvider = context.watch<AuthProvider>();
    final depProvider = context.watch<DependentProvider>();
    final selectedDep = depProvider.selectedDependent;
    final hasName = widget.userName != null && widget.userName!.trim().isNotEmpty;

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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DependentsScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: selectedDep != null 
                        ? const Color(0xFFC9932E) 
                        : const Color(0xFF085041),
                    child: selectedDep != null
                        ? Text(
                            selectedDep.fullName[0],
                            style: const TextStyle(color: Colors.white, fontSize: 24),
                          )
                        : const Icon(Icons.person, color: Colors.white, size: 38),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                              : Colors.black54,
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
                            color: Colors.black,
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
                              color: Color(0xFF1D9E75),
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                  border: Border.all(color: const Color(0xFF1D9E75), width: 1.5),
                ),
                child: const Icon(Icons.add, color: Color(0xFF1D9E75), size: 20),
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
                color: selected ? const Color(0xFF085041) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? const Color(0xFF085041) : const Color(0xFFE0E0E0),
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
                      color: selected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weekdayNameFromDate(date),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : Colors.black54,
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

  Widget _buildTodayTab() {
    final todaysMeds = _getMedicationsForDate(_selectedDate);

    return Column(
      children: [
        _buildDateStrip(),
        const SizedBox(height: 24),
        Expanded(
          child: todaysMeds.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: todaysMeds.length,
                  itemBuilder: (context, index) => _MedicationCard(
                    medication: todaysMeds[index],
                    isTaken: _isMedicationTaken(todaysMeds[index], _selectedDate),
                    onToggle: () => _toggleMedicationTaken(todaysMeds[index], _selectedDate),
                    onEdit: () => _openEditMedicationSheet(todaysMeds[index]),
                    onDelete: () => _deleteMedication(todaysMeds[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
                Icon(Icons.check_circle_outline, color: Color(0xFF1D9E75), size: 20),
                SizedBox(width: 8),
                Text(
                  'لا توجد أدوية مجدولة لهذا اليوم',
                  style: TextStyle(color: Color(0xFF085041), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DependentsScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF085041),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: const Text(
                '+ إضافة تابعين',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab() {
    final medications = context.watch<MedicationProvider>().medications;
    final active = medications.where((m) => m.isActive).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9F2E7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('نشطة', style: TextStyle(color: Color(0xFF085041))),
              ),
              const Spacer(),
              const Text('الأدوية المحفوظة', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        Expanded(
          child: active.isEmpty
              ? const Center(
                  child: Text(
                    'لا يوجد أدوية محفوظة بعد',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: active.length,
                  itemBuilder: (context, index) {
                    final uiModel = MedicationUIModel.fromMedication(active[index]);
                    return _MedicationCard(
                      medication: uiModel,
                      showStatus: true,
                      onEdit: () => _openEditMedicationSheet(uiModel),
                      onDelete: () => _deleteMedication(uiModel),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRemindersTab() {
    final todaysMeds = _getMedicationsForDate(_selectedDate);
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Column(
      children: [
        _buildDateStrip(),
        const SizedBox(height: 24),
        Expanded(
          child: todaysMeds.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'لا توجد أدوية مجدولة لهذا اليوم.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: todaysMeds.length,
                  itemBuilder: (context, index) => _buildReminderCard(
                    todaysMeds[index],
                    isToday,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(MedicationUIModel medication, bool isToday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF085041),
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
            final isTaken = _isMedicationTaken(medication, _selectedDate);
            final label = _getDoseTimeLabel(medication, doseIndex);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: isToday
                        ? () => _toggleMedicationTaken(medication, _selectedDate)
                        : null,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isTaken ? const Color(0xFFB85C5C) : Colors.transparent,
                        border: Border.all(color: const Color(0xFFB85C5C), width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isTaken
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

  String _getDoseTimeLabel(MedicationUIModel medication, int doseIndex) {
    final intervalHours = medication.dosesPerDay > 1 ? 24 ~/ medication.dosesPerDay : 0;
    final baseHour = medication.time.hour;
    final baseMinute = medication.time.minute;
    final doseHour = (baseHour + intervalHours * doseIndex) % 24;
    final hour = doseHour.toString().padLeft(2, '0');
    final minute = baseMinute.toString().padLeft(2, '0');
    final period = doseHour < 12 ? 'صباحاً' : 'مساءً';
    return '$hour:$minute $period';
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


class _MedicationCard extends StatelessWidget {
  final MedicationUIModel medication;
  final bool isTaken;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showStatus;

  const _MedicationCard({
    required this.medication,
    this.isTaken = false,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF085041),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(medication.type.icon, color: const Color(0xFF085041)),
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
                if (showStatus)
                  Row(
                    children: [
                      Icon(
                        medication.isActive ? Icons.check_circle : Icons.cancel,
                        color: medication.isActive ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        medication.isActive ? 'نشط' : 'غير نشط',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (onToggle != null)
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isTaken ? const Color(0xFFB85C5C) : Colors.transparent,
                  border: Border.all(color: const Color(0xFFB85C5C), width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isTaken
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
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



class _AddMedicationSheet extends StatefulWidget {
  final String dependentId;
  final MedicationUIModel? initialMedication;
  final Future<void> Function(MedicationUIModel) onSave;

  const _AddMedicationSheet({
    required this.dependentId,
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

  static const List<String> _allDays = [
    'الجمعة', 'السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
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
  void initState() {
    super.initState();
    if (widget.initialMedication != null) {
      _nameController.text = widget.initialMedication!.name;
      _dosageController.text = widget.initialMedication!.dosage;
      _selectedType = widget.initialMedication!.type;
      _selectedDays.addAll(widget.initialMedication!.daysOfWeek);
      _period = widget.initialMedication!.period;
      _time = widget.initialMedication!.time;
      _dosesPerDay = widget.initialMedication!.dosesPerDay;
    }
  }

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

    final uiModel = MedicationUIModel(
      id: widget.initialMedication?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      type: _selectedType,
      daysOfWeek: _selectedDays.toList(),
      period: _period,
      time: _time,
      dosesPerDay: _dosesPerDay,
      reminderEnabled: withReminder,
    );

    await widget.onSave(uiModel);

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
                              color: selected ? _Colors.darkGreen : _Colors.borderGrey,
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
                      borderSide: BorderSide.none,
                    ),
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
                          title: Text(item['name']!, textAlign: TextAlign.right),
                          subtitle: Text(item['dosage']!, textAlign: TextAlign.right),
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
                          selected ? _selectedDays.remove(day) : _selectedDays.add(day);
                        }),
                        child: Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? _Colors.darkGreen : Colors.white,
                            border: Border.all(
                              color: selected ? _Colors.darkGreen : _Colors.borderGrey,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(day,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selected ? Colors.white : _Colors.textPrimary,
                                  )),
                              const SizedBox(height: 4),
                              Icon(
                                selected ? Icons.check_circle : Icons.circle_outlined,
                                size: 14,
                                color: selected ? Colors.white : _Colors.borderGrey,
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
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'صباحا', child: Text('صباحا')),
                              DropdownMenuItem(value: 'مساء', child: Text('مساء')),
                            ],
                            onChanged: (value) => setState(() => _period = value!),
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
                                vertical: 14, horizontal: 12,
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
                              color: selected ? _Colors.mutedGreen : _Colors.darkGreen,
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
                    onPressed: () async => _save(withReminder: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Colors.darkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'حفظ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async => _save(withReminder: false),
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
