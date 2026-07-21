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
import 'package:app_links/app_links.dart';
import 'views/dashboard/invite_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await NotificationService.requestPermission();
  runApp(const DawaiApp());
}

class DawaiApp extends StatefulWidget {
  const DawaiApp({super.key});

  @override
  State<DawaiApp> createState() => _DawaiAppState();
}

class _DawaiAppState extends State<DawaiApp> {
  String? _initialRoute;
  String? _inviteToken;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

Future<void> _handleDeepLinks() async {
    try {
      final appLinks = AppLinks();
      
      // getInitialLink() returns Uri? in app_links v6.4.1
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        _handleUri(initialLink);
      }

      // uriLinkStream emits Uri objects in app_links v6.4.1
      appLinks.uriLinkStream.listen((uri) {
        _handleUri(uri);
      });
    } catch (e) {
      print('Deep Link Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _handleUri(Uri uri) {
    final link = uri.toString();
    print('Deep Link received: $link');
    
    if (link.contains('/invite/')) {
      final token = link.split('/invite/').last;
      setState(() {
        _inviteToken = token;
        _initialRoute = '/invite';
      });
    }
  }

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
            home: _buildHome(),
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }

  Widget _buildHome() {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_initialRoute == '/invite' && _inviteToken != null && _inviteToken!.isNotEmpty) {
      return InviteScreen(token: _inviteToken!);
    }

    return const _AuthGate();
  }

  Route? _onGenerateRoute(RouteSettings settings) {
    if (settings.name == '/invite') {
      final token = settings.arguments as String? ?? _inviteToken ?? '';
      if (token.isNotEmpty) {
        return MaterialPageRoute(
          builder: (context) => InviteScreen(token: token),
        );
      }
    }
    return null;
  }
}

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