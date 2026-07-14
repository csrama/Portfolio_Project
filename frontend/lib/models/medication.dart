class Medication {
  final String id;
  final String name;
  final String genericName;
  final String dosage;
  final String form;
  final List<String> times;
  final List<String> daysOfWeek;
  final String dependentId;
  final String? instructions;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? interactions;

  Medication({
    required this.id,
    required this.name,
    required this.genericName,
    required this.dosage,
    required this.form,
    required this.times,
    required this.daysOfWeek,
    required this.dependentId,
    this.instructions,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.interactions,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genericName: json['generic_name']?.toString() ?? json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      form: json['form']?.toString() ?? 'tablet',
      times: json['times'] != null ? List<String>.from(json['times']) : [],
      daysOfWeek: json['days_of_week'] != null ? List<String>.from(json['days_of_week']) : [],
      dependentId: json['dependent_id']?.toString() ?? '',
      instructions: json['instructions']?.toString(),
      isActive: json['is_active'] ?? true,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      interactions: json['interactions'] != null ? List<String>.from(json['interactions']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'generic_name': genericName,
      'dosage': dosage,
      'form': form,
      'times': times,
      'days_of_week': daysOfWeek,
      'dependent_id': dependentId,
      'instructions': instructions,
      'is_active': isActive,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'interactions': interactions,
    };
  }

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  bool get isTimeToTake {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    for (String time in times) {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final doseTime = DateTime(now.year, now.month, now.day, hour, minute);
      final diff = now.difference(doseTime);
      
      if (diff.inMinutes.abs() <= 5) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() => 'Medication(id: $id, name: $name)';
}
