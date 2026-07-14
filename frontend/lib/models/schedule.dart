class MedicationSummary {
  final int id;
  final String name;
  final String dosage;
  final String form;
  final String instructions;
  final bool isActive;

  MedicationSummary({
    required this.id,
    required this.name,
    required this.dosage,
    required this.form,
    required this.instructions,
    this.isActive = true,
  });
}
