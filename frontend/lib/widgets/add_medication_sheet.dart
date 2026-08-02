import 'package:flutter/material.dart';
import '../models/medication_item.dart';
import '../i18n/strings.dart';

class _Colors {
  static const Color primaryGreen = Color(0xFF1D9E75);
  static const Color darkGreen = Color(0xFF085041);
  static const Color mutedGreen = Color(0xFF7FBF9E);
  static const Color borderGrey = Color(0xFFE0E0E0);
}

class AddMedicationSheet extends StatefulWidget {
  final Future<void> Function(MedicationItem medication) onSave;
  const AddMedicationSheet({super.key, required this.onSave});

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  MedicationType _selectedType = MedicationType.tablets;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final Set<String> _selectedDays = {};

  String _period = 'morning';
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
    return _pharmacySuggestions
        .where((item) => item['name']!.toLowerCase().contains(query))
        .toList();
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
        SnackBar(content: Text(Strings.tr(context, 'enter_name_and_days'))),
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
    if (mounted) {}
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                Strings.tr(context, 'add_medication_sheet_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Strings.tr(context, 'select_medication_type'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  Strings.tr(context, 'medication_name'),
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: Strings.tr(context, 'search_pharmacy_hint'),
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
                        title: Text(item['name']!),
                        subtitle: Text(item['dosage']!),
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
                      decoration: InputDecoration(
                        hintText: 'Eltroxin',
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
                              day.substring(0, 3),
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? Colors.white
                                    : theme.textTheme.bodyLarge?.color,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Strings.tr(context, 'period_label'),
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _period,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF6F6F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'morning',
                              child: Text(Strings.tr(context, 'morning')),
                            ),
                            DropdownMenuItem(
                              value: 'evening',
                              child: Text(Strings.tr(context, 'evening')),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Strings.tr(context, 'time_label'),
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  Strings.tr(context, 'doses_per_day'),
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
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
                  child: Text(
                    Strings.tr(context, 'save'),
                    style: const TextStyle(
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
                    side: const BorderSide(
                      color: _Colors.darkGreen,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    Strings.tr(context, 'save_without_reminder'),
                    style: const TextStyle(
                      color: _Colors.darkGreen,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
