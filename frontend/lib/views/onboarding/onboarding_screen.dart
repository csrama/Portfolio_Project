import 'package:flutter/material.dart'
    show
        Alignment,
        BorderRadius,
        BorderSide,
        BoxDecoration,
        BuildContext,
        Center,
        CircularProgressIndicator,
        Color,
        Colors,
        Column,
        Container,
        CrossAxisAlignment,
        Directionality,
        Divider,
        DropdownButtonFormField,
        DropdownMenuItem,
        EdgeInsets,
        ElevatedButton,
        Expanded,
        FontWeight,
        Icon,
        Icons,
        InputDecoration,
        LinearGradient,
        MainAxisAlignment,
        MaterialPageRoute,
        Navigator,
        OutlineInputBorder,
        OutlinedButton,
        Padding,
        RoundedRectangleBorder,
        Row,
        SafeArea,
        Scaffold,
        ScaffoldMessenger,
        SingleChildScrollView,
        SizedBox,
        SnackBar,
        State,
        StatefulWidget,
        Text,
        TextAlign,
        TextButton,
        TextDirection,
        TextEditingController,
        TextField,
        TextInputType,
        TextStyle,
        Theme,
        VoidCallback,
        Widget;
import '../dashboard/home_screen.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../i18n/strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
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
        SnackBar(content: Text(Strings.tr(context, 'signup_error'))),
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
          'user_type': _userType,
        },
      );

      final token = result['token']?.toString();
      final refreshToken = result['refreshToken']?.toString();
      final user = result['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw Exception(Strings.tr(context, 'incomplete_data'));
      }

      await context.read<AuthProvider>().login(token, refreshToken ?? '', user);

      if (!mounted) return;
      final isOffline = result['mode'] == 'offline';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? Strings.tr(context, 'account_created_offline')
                : '${Strings.tr(context, 'account_created')}: ${user['full_name']}',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: user['full_name']?.toString(),
            photoUrl: null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('409')
          ? Strings.tr(context, 'email_exists')
          : Strings.tr(context, 'signup_error');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.tr(context, 'login_error'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.postJson(
        '/auth/login',
        body: {'email': email, 'password': password},
      );

      final token = result['token']?.toString();
      final refreshToken = result['refreshToken']?.toString();
      final user = result['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw Exception(Strings.tr(context, 'incomplete_data'));
      }

      await context.read<AuthProvider>().login(token, refreshToken ?? '', user);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: user['full_name']?.toString(),
            photoUrl: null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('401')
          ? Strings.tr(context, 'invalid_credentials')
          : Strings.tr(context, 'login_error');
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
    ).showSnackBar(SnackBar(content: Text(Strings.tr(context, 'done'))));
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final googleAuthService = GoogleAuthService();
      final authResult = await googleAuthService.signInWithBackend(
        authService: _authService,
      );

      if (!context.mounted) return;

      if (authResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Strings.tr(context, 'google_signin_cancelled')),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final token = authResult['token']?.toString();
      final refreshToken = authResult['refreshToken']?.toString();
      final user = authResult['user'] as Map<String, dynamic>?;

      if (token != null && user != null) {
        await context.read<AuthProvider>().login(
          token,
          refreshToken ?? '',
          user,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName:
                  user['full_name']?.toString() ?? user['name']?.toString(),
              photoUrl: user['picture']?.toString(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Strings.tr(context, 'google_signin_incomplete')),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${Strings.tr(context, 'google_signin_error')}: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<AppSettingsProvider>();
    final isRtl = settings.languageCode == 'ar';
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
                      _isSignUp
                          ? Strings.tr(context, 'signup_title')
                          : Strings.tr(context, 'login_title'),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp
                          ? Strings.tr(context, 'signup_subtitle')
                          : Strings.tr(context, 'login_subtitle'),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isSignUp) ...[
                      _buildTextField(
                        controller: _nameController,
                        hint: Strings.tr(context, 'full_name'),
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _userType,
                        decoration: InputDecoration(
                          labelText: Strings.tr(context, 'account_type'),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.85),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'general_user',
                            child: Text(Strings.tr(context, 'general_user')),
                          ),
                          DropdownMenuItem(
                            value: 'caregiver',
                            child: Text(Strings.tr(context, 'caregiver')),
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
                      hint: Strings.tr(context, 'email_label'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _passwordController,
                      hint: Strings.tr(context, 'password_label'),
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
                                _isSignUp
                                    ? Strings.tr(context, 'signup')
                                    : Strings.tr(context, 'login'),
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
                            _isSignUp
                                ? Strings.tr(context, 'login')
                                : Strings.tr(context, 'signup'),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _isSignUp
                              ? Strings.tr(context, 'already_have_account')
                              : Strings.tr(context, 'dont_have_account'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                            thickness: 0.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            Strings.tr(context, 'or'),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                            thickness: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSocialButton(
                      label: Strings.tr(context, 'sign_up_with_google'),
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
                      label: Strings.tr(context, 'sign_up_with_apple'),
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
                    Text(
                      Strings.tr(context, 'terms_text'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
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
                                  builder: (_) =>
                                      const HomeScreen(userName: null),
                                ),
                              );
                            },
                      child: Text(
                        Strings.tr(context, 'guest_continue'),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      textAlign: TextAlign.right,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
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
          borderSide: const BorderSide(color: Color(0xFF085041), width: 1.5),
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
        backgroundColor: Colors.white.withValues(alpha: 0.75),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
