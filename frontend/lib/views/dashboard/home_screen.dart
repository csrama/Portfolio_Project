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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  late final List<DateTime> _dateStrip;
  late DateTime _selectedDate;

  static const List<String> _weekdayAr = [
    'الجمعه',
    'السبت',
    'الاحد',
    'الاثنين',
    'الثلاثاء',
    'الاربعاء',
    'الخميس',
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = today;
    // 7-day rolling strip centered on today, oldest first so it reads
    // naturally left-to-right even inside an RTL Directionality.
    _dateStrip = List.generate(7, (i) => today.add(Duration(days: i - 3)));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'صباح الخير';
    }
    return 'مساء الخير';
  }

  void _openAddMedicationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedicationSheet(
        onSave: (med) => setState(() => _medications.add(med)),
      ),
    );
  }

  // ------------------------- Top bar -------------------------
  Widget _buildTopBar() {
    final hasName =
        widget.userName != null && widget.userName!.trim().isNotEmpty;
    final hasPhoto =
        widget.photoUrl != null && widget.photoUrl!.trim().isNotEmpty;

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
                // Profile avatar - dark green
                CircleAvatar(
                   radius: 26, 
                   backgroundColor: _Colors.darkGreen,
                    child: const Icon(
                       Icons.person,
                       color: Colors.white,
                       size: 38,
                       ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasName ? '${_getGreeting()}،' : _getGreeting(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: hasName ? 16 : 22,
                        fontWeight: hasName ? FontWeight.normal : FontWeight.bold,
                        color: hasName ? _Colors.textSecondary : _Colors.textPrimary,
                      ),
                    ),
                    if (hasName) ...[
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
                  ],
                ),
              ],
            ),
          ),
          // "+" add button on the left side (rendered on the left in RTL)
          GestureDetector(
            onTap: _openAddMedicationSheet,
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
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dateStrip.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _dateStrip[index];
          final selected =
              date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 48,
              decoration: BoxDecoration(
                color: selected ? _Colors.lightGreenBg : Colors.transparent,
                border: selected
                    ? Border.all(color: _Colors.primaryGreen)
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? _Colors.darkGreen : _Colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weekdayAr[date.weekday - 1],
                    style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? _Colors.darkGreen
                          : _Colors.textSecondary,
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
    final todaysMeds = _medications.where((m) => m.isActive).toList();
    return Column(
      children: [
        _buildDateStrip(),
        Expanded(
          child: todaysMeds.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'لا يوجد أدوية للتذكير!\nأضف أدويتك في خانة أدويتي\nلتبدأ تذكيراتك في الحال.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _Colors.primaryGreen,
                        fontSize: 18,
                        height: 1.8,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: todaysMeds.length, // unlimited
                  itemBuilder: (context, index) =>
                      _MedicationCard(medication: todaysMeds[index]),
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
                      _MedicationCard(medication: active[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildRemindersTab() {
    return const Center(
      child: Text(
        'التذكيرات قريبًا',
        style: TextStyle(color: _Colors.textSecondary),
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
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton(
                backgroundColor: _Colors.darkGreen,
                onPressed: _openAddMedicationSheet,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
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

  const _MedicationCard({required this.medication});

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
        children: [
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
  final void Function(MedicationItem medication) onSave;

  const _AddMedicationSheet({required this.onSave});

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
    if (query.isEmpty) {
      return [];
    }
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

  void _save({required bool withReminder}) {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الدواء واختيار الأيام')),
      );
      return;
    }

    widget.onSave(
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
                          title: Text(
                            item['name']!,
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Text(
                            item['dosage']!,
                            textAlign: TextAlign.right,
                          ),
                          trailing: const Icon(
                            Icons.medical_services_outlined,
                            color: _Colors.primaryGreen,
                          ),
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
                          InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(12),
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
