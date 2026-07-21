import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/api_service.dart';

void main() {
  test('builds the backend URL correctly', () {
    expect(
       ApiService.buildUrl('/auth/register'),
  'https://portfolioproject-production-2b3b.up.railway.app/auth/register',
    );
  });
}
