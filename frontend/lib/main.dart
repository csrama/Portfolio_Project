import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/dio_client.dart';
import 'views/dashboard/home_screen.dart';
import 'views/splash/splash_screen.dart';
import 'package:frontend/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(); // Initialize the notification service
  await NotificationService.requestPermission();
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

/// Decides which screen to show at app start:
///  - If a session already exists in secure storage -> HomeScreen
///  - Otherwise -> SplashScreen (which walks through onboarding + login/signup)
///
/// Runs the storage read ONCE (Future is cached in initState). Previously
/// FutureBuilder inside a Consumer created a new Future on every rebuild,
/// which combined with notifyListeners() caused an infinite rebuild loop
/// (blank spinner forever).
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
        if (snapshot.data == true && !snapshot.hasError) {
          final user = context.read<AuthProvider>().user;
          return HomeScreen(
            userName: user?['name'] as String? ?? 'مستخدم',
            photoUrl: user?['photo'] as String?,
          );
        }
        return const SplashScreen();
      },
    );
  }
}
