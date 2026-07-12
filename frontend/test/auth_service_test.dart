import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('falls back to offline signup when online auth fails', () async {
    SharedPreferences.setMockInitialValues({});

    final authService = AuthService();
    final result = await authService.signUp(
      email: 'offline@example.com',
      password: '123456',
      fullName: 'Offline User',
      onlineRequest: (_) async => throw Exception('network unavailable'),
    );

    expect(result['mode'], 'offline');
    expect(result['user']['email'], 'offline@example.com');
    expect(result['user']['full_name'], 'Offline User');
  });
}
