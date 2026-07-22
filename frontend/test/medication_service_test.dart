import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/medication_service.dart';

void main() {
  test('maps backend medication payloads into UI medication items', () {
    final service = MedicationService();

    final medications = service.mapMedications([
      {
        'id': 1,
        'name': 'Paracetamol',
        'dosage': '500mg',
        'form': 'tablet',
        'instructions': 'Take after lunch',
        'is_active': true,
      },
    ]);

    expect(medications.length, 1);
    expect(medications.first.name, 'Paracetamol');
    expect(medications.first.dosage, '500mg');
  });
}
