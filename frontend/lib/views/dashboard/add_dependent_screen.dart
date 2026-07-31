import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AddDependentScreen extends StatefulWidget {
  const AddDependentScreen({super.key});

  @override
  State<AddDependentScreen> createState() => _AddDependentScreenState();
}

class _AddDependentScreenState extends State<AddDependentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedRelationship;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<Map<String, String>> _relationships = [
    {'value': 'spouse', 'label': 'زوج / زوجة'},
    {'value': 'child', 'label': 'ابن / ابنة'},
    {'value': 'parent', 'label': 'أب / أم'},
    {'value': 'sibling', 'label': 'أخ / أخت'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final token = context.read<AuthProvider>().accessToken;
      if (token == null) {
        _showSnack('يرجى تسجيل الدخول أولاً', Colors.red);
        return;
      }

      String? dateOfBirth;
      final age = int.tryParse(_ageController.text.trim());
      if (age != null && age > 0) {
        final now = DateTime.now();
        dateOfBirth = DateTime(now.year - age, now.month, now.day)
            .toIso8601String();
      }

      final response = await ApiService.postJson(
        '/dependents/create-with-account',
        token: token,
        body: {
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'relationship': _selectedRelationship,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        _showSnack(
          response['message'] ?? 'تم إنشاء حساب التابع وربطه بنجاح',
          const Color(0xFF085041),
        );
        Navigator.pop(context, true);
      } else {
        _showSnack(response['error'] ?? 'حدث خطأ غير متوقع', Colors.red);
      }
    } catch (e) {
      _showSnack('خطأ: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة تابع'),
        backgroundColor: const Color(0xFF085041),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF6F6F6),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني للتابع',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF6F6F6),
                ),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'بريد إلكتروني غير صحيح'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFFF6F6F6),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'كلمة المرور 6 أحرف على الأقل'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'العمر (اختياري)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF6F6F6),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'العلاقة',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF6F6F6),
                ),
                value: _selectedRelationship,
                items: _relationships
                    .map((r) => DropdownMenuItem(
                          value: r['value'],
                          child: Text(r['label']!),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRelationship = v),
                validator: (v) => v == null ? 'يرجى اختيار العلاقة' : null,
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم إنشاء حساب للتابع. شارك بيانات الدخول (البريد الإلكتروني وكلمة المرور) معه.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF085041),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'إنشاء الحساب وإضافة التابع',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
