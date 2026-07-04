import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/api_service.dart';

void main() {
  test('builds the backend URL correctly', () {
    expect(
      ApiService.buildUrl('/auth/register'),
      'http://10.0.2.2:3000/auth/register',
    );
  });
}
