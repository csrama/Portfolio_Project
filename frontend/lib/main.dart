import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/app_settings_provider.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/dependent_service.dart';
import 'providers/dependent_provider.dart';
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
        Provider<DependentService>(
          create: (_) => DependentService(apiService: ApiService()),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<DependentProvider>(
          create: (context) => DependentProvider(
            dependentService: context.read<DependentService>(),
          ),
        ),
        Provider<DioClient>(
          create: (_) => DioClient(),
        ),
        ChangeNotifierProvider<AppSettingsProvider>(
          create: (_) => AppSettingsProvider()..load(),
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Dawai',
            locale: settings.locale,
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 2, 111, 38),
              ),
              fontFamily: 'Cairo',
            ),
            darkTheme: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 2, 111, 38),
                brightness: Brightness.dark,
              ),
            ),
            themeMode: settings.themeMode,
            home: const _AuthGate(),
          );
        },
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
