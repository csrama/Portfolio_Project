import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dependent_provider.dart';
import 'providers/medication_provider.dart';
import 'services/auth_service.dart';
import 'services/dependent_service.dart';
import 'services/medication_service.dart';
import 'views/splash/splash_screen.dart';
import 'views/dashboard/home_screen.dart';
import 'views/dashboard/dependents_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'config/environment.dart';

void main() {
  Environment.printEnvironmentInfo();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: AuthService(),
          ),
        ),
        
        Provider(create: (_) => DependentService()),
        Provider(create: (_) => MedicationService()),
        
        ChangeNotifierProvider(create: (context) => DependentProvider()),
        ChangeNotifierProvider(create: (context) => MedicationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedTrack',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Cairo',
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/dependents': (context) => const DependentsScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}
