import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/dependent.dart';
import '../../models/medication_item.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/dependent_service.dart';
import '../../services/notification_service.dart';

class _Colors {
  static const Color primaryGreen = Color(0xFF1D9E75);
  static const Color darkGreen = Color(0xFF085041);
  static const Color lightGreenBg = Color(0xFFD9F2E7);
  static const Color mutedGreen = Color(0xFF7FBF9E);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black54;
  static const Color borderGrey = Color(0xFFE0E0E0);
}

class DependentDashboardScreen extends StatefulWidget {
  final Dependent dependent;

  const DependentDashboardScreen({super.key, required this.dependent});

  @override
  State<DependentDashboardScreen> createState() => _DependentDashboardScreenState();
}

class _DependentDashboardScreenState extends State<DependentDashboardScreen> {
  List<MedicationItem> _medications = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final depService = context.read<DependentService>();
      final rawList = await depService.getDependentMedications(
        auth.accessToken!,
        widget.dependent.id,
      );

      setState(() {
        _medications = rawList.map((m) {
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
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD DEP MEDICATIONS ERROR = $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل في تحميل الأدوية';
      });
    }
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("حذف"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final auth = context.read<AuthProvider>();
    if (auth.accessToken == null) return;

    try {
      await http.delete(
        Uri.parse(ApiService.buildUrl('/medications/${med.id}')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.accessToken!}',
        },
      );
      await _loadMedications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' تم حذف الدواء بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' فشل الحذف'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openAddMedicationSheet({MedicationItem? existingMedication}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDependentMedicationSheet(
        existingMedication: existingMedication,
        dependentId: widget.dependent.id,
        onSave: () async {
          await _loadMedications();
        },
      ),
    );
  }

  Future<void> _searchMedications(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final auth = context.read<AuthProvider>();
    try {
      final result = await ApiService.getJsonList(
        '/medicines/search?q=$query',
        token: auth.accessToken!,
      );
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(result);
      });
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _addFoundMedicineFromSearch(Map<String, dynamic> med) async {
    final auth = context.read<AuthProvider>();
    if (auth.accessToken == null) return;

    try {
      await ApiService.postJson(
        '/medications',
        body: {
          'dependent_id': int.parse(widget.dependent.id.toString()),
          'name': (med['name_ar']?.toString()?.isNotEmpty == true
              ? '${med['name_en']} — ${med['name_ar']}'
              : med['name_en'] ?? '').toString(),
          'dosage': med['dosage'] ?? '',
          'type': 0,
          'days_of_week': [],
          'period': 'صباحا',
          'time': '08:00',
          'doses_per_day': 1,
        },
        token: auth.accessToken!,
      );
      _searchController.clear();
      setState(() {
        _searchResults.clear();
      });
      await _loadMedications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' تم إضافة الدواء بنجاح'),
            backgroundColor: _Colors.darkGreen,
          ),
        );
      }
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint('Add from search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' فشل الإضافة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('ملف: ${widget.dependent.fullName}'),
        backgroundColor: _Colors.darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- Search Section ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: _Colors.darkGreen,
            child: TextField(
              controller: _searchController,
              onChanged: _searchMedications,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث عن دواء لإضافته للتابع...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.search, color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // --- Search Results Dropdown ---
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
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
                    trailing: const Icon(Icons.add_circle_outline, color: _Colors.darkGreen),
                    onTap: () => _addFoundMedicineFromSearch(item),
                  );
                },
              ),
            ),

          // --- Content ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMedications,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMedications,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // --- Dependent Info Card ---
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _Colors.borderGrey),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: const Color(0xFFC9932E),
                                    child: Text(
                                      widget.dependent.fullName.isNotEmpty
                                          ? widget.dependent.fullName[0]
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.dependent.fullName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _Colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'صلة القرابة: ${widget.dependent.relationship}',
                                          style: const TextStyle(
                                            color: _Colors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (widget.dependent.dateOfBirth != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              'تاريخ الميلاد: ${widget.dependent.dateOfBirth!.toString().split(' ')[0]}',
                                              style: const TextStyle(
                                                color: _Colors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // --- Medications Section Header ---
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
                                const Text(
                                  'عرض المزيد',
                                  style: TextStyle(
                                    color: Colors.transparent,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'الأدوية',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _Colors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // --- Medications List ---
                            if (_medications.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1F5EE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        color: Color(0xFF1D9E75), size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'لم يتم إضافة أي أدوية لهذا التابع بعد',
                                      style: TextStyle(
                                        color: Color(0xFF085041),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._medications.map((med) => _buildMedicationCard(med)),
                            const SizedBox(height: 16),

                            // --- Add Medication Button ---
                            GestureDetector(
                              onTap: () => _openAddMedicationSheet(),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _Colors.darkGreen,
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
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(MedicationItem medication) {
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
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == "edit") {
                _openAddMedicationSheet(existingMedication: medication);
              }
              if (value == "delete") {
                _deleteMedication(medication);
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


class _AddDependentMedicationSheet extends StatefulWidget {
  final MedicationItem? existingMedication;
  final String dependentId;
  final VoidCallback onSave;

  const _AddDependentMedicationSheet({
    this.existingMedication,
    required this.dependentId,
    required this.onSave,
  });

  @override
  State<_AddDependentMedicationSheet> createState() => _AddDependentMedicationSheetState();
}

class _AddDependentMedicationSheetState extends State<_AddDependentMedicationSheet> {
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
      setState(() => _pharmacySuggestions.clear());
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
      _nameController.text = nameAr.isNotEmpty ? '$nameEn — $nameAr' : nameEn;
      _dosageController.text = suggestion['dosage'] ?? '';
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

  void _save({required bool withReminder}) async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الدواء واختيار الأيام')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.accessToken == null) return;

    try {
      if (widget.existingMedication != null) {
        // Update existing medication
        await ApiService.putJson(
          '/medications/${widget.existingMedication!.id}',
          body: {
            'name': _nameController.text.trim(),
            'dosage': _dosageController.text.trim(),
            'type': _selectedType.index,
            'days_of_week': _selectedDays.toList(),
            'period': _period,
            'time': '${_time.hour}:${_time.minute}',
            'doses_per_day': _dosesPerDay,
          },
          token: auth.accessToken!,
        );
      } else {
        // Add new medication for dependent
        await ApiService.postJson(
          '/medications',
          body: {
            'dependent_id': int.parse(widget.dependentId.toString()),
            'name': _nameController.text.trim(),
            'dosage': _dosageController.text.trim(),
            'type': _selectedType.index,
            'days_of_week': _selectedDays.toList(),
            'period': _period,
            'time': '${_time.hour}:${_time.minute}',
            'doses_per_day': _dosesPerDay,
          },
          token: auth.accessToken!,
        );
      }

      if (withReminder) {
        await NotificationService.scheduleMedicineReminder(
          id: DateTime.now().millisecondsSinceEpoch,
          medicineName: _nameController.text.trim(),
          hour: _time.hour,
          minute: _time.minute,
        );
      }

      widget.onSave();
      Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingMedication != null
                ? ' تم تعديل الدواء بنجاح'
                : ' تم إضافة الدواء بنجاح'),
            backgroundColor: _Colors.darkGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Save medication error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' فشل الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                Text(
                  widget.existingMedication != null
                      ? 'تعديل دواء للتابع'
                      : 'إضافة دواء للتابع',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                  child: Text('اسم الدواء', style: TextStyle(color: _Colors.textSecondary)),
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
                          trailing: const Icon(Icons.medical_services_outlined,
                              color: _Colors.primaryGreen),
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
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected ? Colors.white : _Colors.textPrimary,
                                ),
                              ),
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
                          const Text('الفترة', style: TextStyle(color: _Colors.textSecondary)),
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
                          const Text('الوقت', style: TextStyle(color: _Colors.textSecondary)),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_time.format(context), textAlign: TextAlign.center),
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

