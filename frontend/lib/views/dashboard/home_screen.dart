import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/dependent_provider.dart';
import '../../models/medication.dart';
import '../../models/dependent.dart';
import 'dependents_screen.dart';
import '../onboarding/onboarding_screen.dart';


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

  
  // retrieve from Providers
  
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
              .updateMedication(medication);
          
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
