import 'package:flutter/material.dart';

enum MedicationType {
  pill(Icons.medication),
  syrup(Icons.local_drink),
  injection(Icons.vaccines);

  final IconData icon;
  const MedicationType(this.icon);
}

class Medication {
  final String name;
  final String dosage;
  final String timeLabel;
  final int dosesPerDay;
  final MedicationType type;
  final bool isActive;

  Medication({
    required this.name,
    required this.dosage,
    required this.timeLabel,
    required this.dosesPerDay,
    this.type = MedicationType.pill,
    this.isActive = true,
  });
}
