class DoseRecord {
  final String id;
  final String medicationId;
  final String dependentId;
  final DateTime scheduledTime;  
  final DateTime? takenTime; 
  final bool isTaken; 

  // Constructor 
  DoseRecord({
    required this.id,
    required this.medicationId,
    required this.dependentId,
    required this.scheduledTime,
    required this.isTaken,
    this.takenTime,
  });

  // fromJson 
  factory DoseRecord.fromJson(Map<String, dynamic> json) {
    return DoseRecord(
      id: json['id']?.toString() ?? '',
      medicationId: json['medication_id']?.toString() ?? '',
      dependentId: json['dependent_id']?.toString() ?? '',
      scheduledTime: DateTime.parse(json['scheduled_time']),
      isTaken: json['is_taken'] ?? false,
      takenTime: json['taken_time'] != null 
          ? DateTime.parse(json['taken_time']) 
          : null,
    );
  }

  // toJson 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'dependent_id': dependentId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'is_taken': isTaken,
      'taken_time': takenTime?.toIso8601String(),
    };
  }

  
  bool get isLate {
    if (isTaken && takenTime != null) {
      return takenTime!.isAfter(scheduledTime.add(const Duration(minutes: 10)));
    }
    if (!isTaken) {
      return DateTime.now().isAfter(scheduledTime.add(const Duration(minutes: 10)));
    }
    return false;
  }

  bool get isMissed {
    if (isTaken) return false;
    return DateTime.now().isAfter(scheduledTime.add(const Duration(hours: 2)));
  }

  String get status {
    if (isTaken) return 'Taken ';
    if (isMissed) return 'Missed ';
    if (isLate) return 'Late ';
    return 'Pending ';
  }
}
