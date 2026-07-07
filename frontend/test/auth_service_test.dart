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

  test('logout clears the saved session', () async {
    SharedPreferences.setMockInitialValues({});

    final authService = AuthService();
    await authService.signUp(
      email: 'session@example.com',
      password: '123456',
      fullName: 'Session User',
      onlineRequest: (_) async => {
        'token': 'demo-token',
        'user': {'full_name': 'Session User'}
      },
    );

    expect(await authService.hasSession(), isTrue);

    await authService.logout();

    expect(await authService.hasSession(), isFalse);
    expect(await authService.getToken(), isNull);
  });
}
