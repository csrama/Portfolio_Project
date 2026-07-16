// lib/models/medication_item.dart
//
// موديل الدواء المشترك — تم فصله من home_screen.dart عشان
// يستخدم من أكثر من شاشة (home_screen + dependent_dashboard_screen)
// بدون تكرار الكود.

import 'package:flutter/material.dart';

enum MedicationType { drops, cream, injection, bottle, tablets, capsule }

extension MedicationTypeIcon on MedicationType {
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

  /// يحوّل الدواء إلى Map جاهزة للإرسال للـ API.
  /// [dependentId] لو null => الدواء يُحفظ للمستخدم نفسه.
  /// لو فيه قيمة => الدواء يُحفظ للتابع صاحب هذا الـ id.
  Map<String, dynamic> toApiJson({String? dependentId}) {
    return {
      if (dependentId != null) 'dependent_id': dependentId,
      'name': name,
      'dosage': dosage,
      'type': type.index,
      'days_of_week': daysOfWeek,
      'period': period,
      'time': '${time.hour}:${time.minute}',
      'doses_per_day': dosesPerDay,
    };
  }
}