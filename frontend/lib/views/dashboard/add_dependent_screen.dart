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
  int _selectedMode = 0;

  final _formKey = GlobalKey<FormState>();

  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  final _existingEmailController = TextEditingController();

  String? _selectedRelationship;
  bool _isLoading       = false;
  bool _obscurePassword = true;

  final List<Map<String, String>> _relationships = [
    {'value': 'spouse',  'label': 'زوج / زوجة'},
    {'value': 'child',   'label': 'ابن / ابنة'},
    {'value': 'parent',  'label': 'أب / أم'},
    {'value': 'sibling', 'label': 'أخ / أخت'},
    {'value': 'other',   'label': 'أخرى'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _existingEmailController.dispose();
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

      Map<String, dynamic> response;

      if (_selectedMode == 0) {
        response = await ApiService.postJson(
          '/dependents/create-with-account',
          token: token,
          body: {
            'full_name':    _nameController.text.trim(),
            'email':        _emailController.text.trim(),
            'password':     _passwordController.text,
            'relationship': _selectedRelationship,
          },
        );
      } else {
        response = await ApiService.postJson(
          '/dependents/link-request',
          token: token,
          body: {
            'email':        _existingEmailController.text.trim(),
            'relationship': _selectedRelationship,
          },
        );
      }

      if (!mounted) return;

      if (response['success'] == true) {
        _showSnack(
          response['message'] ?? 'تمت العملية بنجاح',
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
              // ── اختيار النوع ──
              Row(
                children: [
                  Expanded(
                    child: _modeCard(
                      mode: 0,
                      icon: Icons.person_add_alt_1,
                      title: 'تابع جديد',
                      subtitle: 'إنشاء حساب له',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _modeCard(
                      mode: 1,
                      icon: Icons.link,
                      title: 'لديه حساب',
                      subtitle: 'إرسال طلب ربط',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_selectedMode == 0) ..._newAccountFields(),
              if (_selectedMode == 1) ..._existingAccountFields(),

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
                      : Text(
                          _selectedMode == 0
                              ? 'إنشاء الحساب وإضافة التابع'
                              : 'إرسال طلب الربط',
                          style: const TextStyle(
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

  Widget _modeCard({
    required int mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMode = mode;
        _selectedRelationship = null;
        _formKey.currentState?.reset();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF085041) : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF085041) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.white : const Color(0xFF085041),
                size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _newAccountFields() => [
        TextFormField(
          controller: _nameController,
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
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
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
        const SizedBox(height: 14),
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
                  'شارك بيانات الدخول مع التابع عبر واتساب أو رسالة نصية.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ];

  List<Widget> _existingAccountFields() => [
        TextFormField(
          controller: _existingEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني للتابع',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFFF6F6F6),
          ),
          validator: (v) => (v == null || !v.contains('@'))
              ? 'بريد إلكتروني غير صحيح'
              : null,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD9F2E7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.send, color: Color(0xFF085041)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'سيصل للتابع طلب ربط داخل التطبيق ويمكنه القبول أو الرفض.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ];
}
