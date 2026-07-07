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
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return FutureBuilder<bool>(
              future: authProvider.checkLoginStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.data == true) {
                  final user = authProvider.user;
                  return HomeScreen(
                    userName: user?['name'] as String? ?? 'مستخدم',
                    photoUrl: user?['photo'] as String?,
                  );
                }

                return const LoginScreen();
              },
            );
          },
        ),
      ),
    );
  }
}
