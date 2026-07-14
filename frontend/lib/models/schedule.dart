class Schedule {
  final String id;
  final String dependentId;
  final DateTime date;  
  final List<ScheduleItem> items; 

  // Constructor 
  Schedule({
    required this.id,
    required this.dependentId,
    required this.date,
    this.items = const [],
  });

  // fromJson 
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id']?.toString() ?? '',
      dependentId: json['dependent_id']?.toString() ?? '',
      date: DateTime.parse(json['date']),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => ScheduleItem.fromJson(i))
              .toList()
          : [],
    );
  }

  // toJson 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dependent_id': dependentId,
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  int get totalDoses => items.length;
  
  int get takenDoses => items.where((i) => i.isTaken).length;
  
  int get pendingDoses => items.where((i) => !i.isTaken).length;
  
  double get adherenceRate => totalDoses > 0 
      ? (takenDoses / totalDoses) * 100 
      : 0.0;
}

class ScheduleItem {
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String scheduledTime; // '08:00'
  final bool isTaken;
  final String? takenTime;
  
  ScheduleItem({
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
    this.isTaken = false,
    this.takenTime,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      medicationId: json['medication_id']?.toString() ?? '',
      medicationName: json['medication_name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      scheduledTime: json['scheduled_time']?.toString() ?? '',
      isTaken: json['is_taken'] ?? false,
      takenTime: json['taken_time']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medication_id': medicationId,
      'medication_name': medicationName,
      'dosage': dosage,
      'scheduled_time': scheduledTime,
      'is_taken': isTaken,
      'taken_time': takenTime,
    };
  }
}
