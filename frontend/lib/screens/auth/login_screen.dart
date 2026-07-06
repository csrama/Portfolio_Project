import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  void _simulateGoogleLogin() async {
    final accessToken = 'your-access-token-from-server';
    final refreshToken = 'your-refresh-token-from-server';
    final userData = {
      'id': '1',
      'email': 'user@example.com',
      'name': 'Test User',
      'avatar': 'https://example.com/avatar.jpg',
    };

    final success = await context.read<AuthProvider>().login(
          accessToken,
          refreshToken,
          userData,
        );

    if (success) {
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تسجيل الدخول')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'مرحباً بك في تطبيق دوائي',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _simulateGoogleLogin,
              icon: const Icon(Icons.login),
              label: const Text('تسجيل الدخول عبر Google'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
              },
              icon: const Icon(Icons.apple),
              label: const Text('تسجيل الدخول عبر Apple'),
            ),
          ],
        ),
      ),
    );
  }
}
