import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/dio_client.dart';
import 'views/dashboard/home_screen.dart';
import 'views/auth/login_screen.dart';

void main() {
  runApp(const DawaiApp());
}

class DawaiApp extends StatelessWidget {
  const DawaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            authService: context.read<AuthService>(),
          ),
        ),
        Provider<DioClient>(
          create: (_) => DioClient(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dawai App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Cairo',
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Runs checkLoginStatus ONCE (not on every rebuild) and switches between
/// LoginScreen / HomeScreen based on the result. Previously main.dart called
/// authProvider.checkLoginStatus() directly inside FutureBuilder, which
/// created a new Future on every rebuild -> notifyListeners caused rebuild
/// -> new Future -> infinite loop (blank spinner forever).
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<bool> _initFuture;

  @override
  void initState() {
    super.initState();
    // Call once, cache the Future.
    _initFuture = context.read<AuthProvider>().checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data != true) {
          return const LoginScreen();
        }
        final user = context.read<AuthProvider>().user;
        return HomeScreen(
          userName: user?['name'] as String? ?? 'مستخدم',
          photoUrl: user?['photo'] as String?,
        );
      },
    );
  }
}
