import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dashboard/home_screen.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import '../../providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  
  bool _isLoading = false;
  bool _isSignUp = false;
  String _userType = 'general_user';

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
          content: Text('أدخل اسمًا صالحًا وبريدًا وكلمة مرور 6 أحرف على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        fullName: name,
      );

      final token = result['token']?.toString();
      final user = result['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw Exception('بيانات غير مكتملة من الخادم');
      }

      await context.read<AuthProvider>().loginWithData(
        token: token,
        userData: user,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ' تم إنشاء الحساب بنجاح: ${user['full_name']}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: user['full_name']?.toString(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      final message = e.toString().contains('409')
          ? ' هذا البريد مستخدم بالفعل'
          : ' فشل إنشاء الحساب: $e';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل البريد وكلمة المرور'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      final token = result['token']?.toString();
      final user = result['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw Exception('بيانات غير مكتملة من الخادم');
      }

      await context.read<AuthProvider>().loginWithData(
        token: token,
        userData: user,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: user['full_name']?.toString(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      final message = e.toString().contains('401')
          ? ' البريد أو كلمة المرور غير صحيحة'
          : ' فشل تسجيل الدخول: $e';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      final authResult = await _googleAuthService.signInWithGoogle();

      if (!mounted) return;

      if (authResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء تسجيل الدخول أو فشل الإعداد'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final token = authResult['token']?.toString();
      final user = authResult['user'] as Map<String, dynamic>?;

      if (token != null && user != null) {
        await context.read<AuthProvider>().loginWithData(
          token: token,
          userData: user,
        );

        if (!mounted) return;

        final userName = user['full_name']?.toString() ?? user['name']?.toString();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: userName,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بيانات تسجيل الدخول غير مكتملة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' حدث خطأ أثناء تسجيل الدخول: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(' قريباً...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFB8DFC8),
                Color(0xFF9DD4B0),
                Color(0xFFCEE8CF),
                Color(0xFFD9EDD5),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isSignUp ? 'انشاء حساب جديد' : 'تسجيل الدخول',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0E3C30),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp
                          ? 'ادخل بياناتك لإنشاء حساب جديد'
                          : 'أدخل بريدك الالكتروني لتسجيل الدخول',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isSignUp) ...[
                      _buildTextField(
                        controller: _nameController,
                        hint: 'الاسم الكامل',
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 12),
                      
                      DropdownButtonFormField<String>(
                        value: _userType,
                        decoration: InputDecoration(
                          labelText: 'نوع الحساب',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.85),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'general_user',
                            child: Text('مستخدم'),
                          ),
                          DropdownMenuItem(
                            value: 'caregiver',
                            child: Text('مقدم رعاية'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _userType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildTextField(
                      controller: _emailController,
                      hint: 'email@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _passwordController,
                      hint: 'كلمة المرور',
                      obscure: true,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF085041),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_isSignUp) {
                                  _signUpWithEmail(context);
                                } else {
                                  _signInWithEmail(context);
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'إنشاء حساب' : 'استمر',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                            style: const TextStyle(
                              color: Color(0xFF085041),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _isSignUp ? 'لديك حساب؟' : 'ليس لديك حساب؟',
                          style: const TextStyle(
                            color: Color(0xFF2D6A4F),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(
                            color: Color(0xFF2D6A4F),
                            thickness: 0.5,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'أو',
                            style: TextStyle(
                              color: Color(0xFF2D6A4F),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Color(0xFF2D6A4F),
                            thickness: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSocialButton(
                      label: 'Sign up with Google',
                      icon: const Icon(
                        Icons.g_mobiledata,
                        size: 24,
                        color: Colors.black87,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _signInWithGoogle(context),
                    ),
                    const SizedBox(height: 10),

                    _buildSocialButton(
                      label: 'Sign up with Apple',
                      icon: const Icon(
                        Icons.apple,
                        size: 22,
                        color: Colors.black87,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _showComingSoon(context),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'عند الضغط على متابعة، أنت توافق على شروط الخدمة وسياسة الخصوصية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF2D6A4F),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(
                                    userName: null,
                                  ),
                                ),
                              );
                            },
                      child: const Text(
                        'الاستمرار كضيف',
                        style: TextStyle(
                          color: Color(0xFF085041),
                          fontSize: 15,
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


  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      textAlign: TextAlign.right,
      style: const TextStyle(color: Color(0xFF0E3C30)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF7AAE95),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF085041),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white54, width: 1),
        backgroundColor: Colors.white.withOpacity(0.75),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
