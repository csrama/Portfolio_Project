import 'package:flutter/material.dart';
import '../dashboard/home_screen.dart';
import '../../services/api_service.dart';
import '../../services/google_auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmail(BuildContext context) async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || name.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'أدخل اسمًا صالحًا وبريدًا وكلمة مرور 6 أحرف على الأقل',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.postJson(
        '/auth/register',
        body: {
          'email': email,
          'password': password,
          'full_name': name,
          'user_type': 'general_user',
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إنشاء الحساب بنجاح: ${result['user']['full_name']}',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: result['user']['full_name']?.toString(),
            photoUrl: null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('409')
          ? 'هذا البريد مستخدم بالفعل'
          : 'فشل إنشاء الحساب. تأكد من الاتصال بالإنترنت أو جرّب بريدًا آخر';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithEmail(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('أدخل البريد وكلمة المرور')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.postJson(
        '/auth/login',
        body: {'email': email, 'password': password},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم تسجيل الدخول بنجاح')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: result['user']['full_name']?.toString(),
            photoUrl: null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('401')
          ? 'البريد أو كلمة المرور غير صحيحة'
          : 'فشل تسجيل الدخول. تأكد من الاتصال بالإنترنت';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('قريباً')));
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final user = await GoogleAuthService().signIn();
      if (!context.mounted) return;

      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إلغاء تسجيل الدخول')));
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomeScreen(userName: user.displayName, photoUrl: user.photoUrl),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFE8F6EE), Color(0xFFD9F2E7)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'انشاء حساب جديد',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0E3C30),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ادخل بريدك الالكتروني لتسجيل الدخول',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'الاسم الكامل',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'email@gmail.com',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'كلمة المرور',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF085041),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _signInWithEmail(context),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF085041)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _signUpWithEmail(context),
                      child: const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          color: Color(0xFF085041),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.black26)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'أو',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.black26)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black26),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(
                        Icons.g_mobiledata,
                        color: Colors.black87,
                      ),
                      label: const Text(
                        'Sign up with Google',
                        style: TextStyle(color: Colors.black87),
                      ),
                      onPressed: () => _signInWithGoogle(context),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black26),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.apple, color: Colors.black87),
                      label: const Text(
                        'Sign up with Apple',
                        style: TextStyle(color: Colors.black87),
                      ),
                      onPressed: () => _showComingSoon(context),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'عند الضغط على متابعة، أنت توافق على شروط الخدمة وسياسة الخصوصية',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(userName: null),
                          ),
                        );
                      },
                      child: const Text(
                        'الاستمرار كضيف',
                        style: TextStyle(
                          color: Color(0xFF085041),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
