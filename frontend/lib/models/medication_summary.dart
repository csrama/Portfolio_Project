class MedicationSummary {
  final int totalMedications;
  final int activeMedications;
  final int dosesToday;
  final int dosesTakenToday;
  final int missedDoses;
  final int upcomingDoses;       
  final double adherenceRateToday;
  final double adherenceRateWeek;
  final List<String> interactions; 

  // Constructor 
  MedicationSummary({
    this.totalMedications = 0,
    this.activeMedications = 0,
    this.dosesToday = 0,
    this.dosesTakenToday = 0,
    this.missedDoses = 0,
    this.upcomingDoses = 0,
    this.adherenceRateToday = 0.0,
    this.adherenceRateWeek = 0.0,
    this.interactions = const [],
  });

  // fromJson 
  factory MedicationSummary.fromJson(Map<String, dynamic> json) {
    return MedicationSummary(
      totalMedications: json['total_medications'] ?? 0,
      activeMedications: json['active_medications'] ?? 0,
      dosesToday: json['doses_today'] ?? 0,
      dosesTakenToday: json['doses_taken_today'] ?? 0,
      missedDoses: json['missed_doses'] ?? 0,
      upcomingDoses: json['upcoming_doses'] ?? 0,
      adherenceRateToday: (json['adherence_rate_today'] ?? 0).toDouble(),
      adherenceRateWeek: (json['adherence_rate_week'] ?? 0).toDouble(),
      interactions: json['interactions'] != null
          ? List<String>.from(json['interactions'])
          : [],
    );
  }

  // toJson 
  Map<String, dynamic> toJson() {
    return {
      'total_medications': totalMedications,
      'active_medications': activeMedications,
      'doses_today': dosesToday,
      'doses_taken_today': dosesTakenToday,
      'missed_doses': missedDoses,
      'upcoming_doses': upcomingDoses,
      'adherence_rate_today': adherenceRateToday,
      'adherence_rate_week': adherenceRateWeek,
      'interactions': interactions,
    };
  }

  bool get hasInteractions => interactions.isNotEmpty;
  
  String get adherenceStatus {
    if (adherenceRateToday >= 90) return 'Excellent';
    if (adherenceRateToday >= 70) return 'Good';
    if (adherenceRateToday >= 50) return 'Needs Improvement';
    return 'Critical';
  }
}
