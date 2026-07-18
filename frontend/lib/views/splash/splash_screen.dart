import 'dart:async';
import '../../providers/app_settings_provider.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../dashboard/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../dashboard/home_screen.dart';
import '../../repositories/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late Timer _timer;

  static final _pages = [
    _SplashPage(
      title: 'دوائي',
      child: Image.asset(
        'assets/app_icon.png',
        width: 120,
        height: 120,
      ),
    ),
    _SplashPage(
      child: Text(
        'مرحبا بك في تطبيق دوائي',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D9E75),
        ),
      ),
    ),
    _SplashPage(
      child: Text(
        'حيث أن دوائك في وقته',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D9E75),
        ),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_currentPage < _pages.length - 1) {
        _currentPage++;
        _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel();
        final authService = AuthService();
        final hasSession = await authService.hasSession();
        final userName = hasSession ? await authService.getStoredUserName() : null;

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => hasSession
                ? HomeScreen(userName: userName, photoUrl: null)
                : const OnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final settings = context.watch<AppSettingsProvider>();
    final isRtl = settings.languageCode == 'ar';
    final textDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFE8F1E9), Color(0xFFB6D3C2)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: PageView.builder(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _pages[index],
          ),
        ),
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  final Widget child;
  final String? title;

  const _SplashPage({required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (title != null) ...[
            const SizedBox(height: 24),
            Text(
              title!,
              style: const TextStyle(
                color: Color(0xFF1D9E75),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
