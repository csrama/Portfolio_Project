// lib/views/dashboard/add_dependent_screen.dart
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
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedRelationship;
  bool _isLoading = false;

  final List<Map<String, String>> _relationships = [
    {'value': 'spouse', 'label': 'زوج/زوجة'},
    {'value': 'child', 'label': 'ابن/ابنة'},
    {'value': 'parent', 'label': 'أب/أم'},
    {'value': 'sibling', 'label': 'أخ/أخت'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim();
    final relationship = _selectedRelationship;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.accessToken;

      if (token == null) {
        _showSnackBar('الرجاء تسجيل الدخول أولاً', Colors.red);
        return;
      }

      final body = {
        'email': email,
        'full_name': fullName,
        'relationship': relationship,
      };

      final response = await ApiService.postJson(
        '/dependents',
        body: body,
        token: token,
      );

      if (response['success'] == true) {
        _showSnackBar('تم إرسال الدعوة بنجاح', const Color(0xFF085041));
        Navigator.pop(context, true);
      } else {
        _showSnackBar(
          response['error'] ?? 'فشل إرسال الدعوة',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('حدث خطأ: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال دعوة'),
        backgroundColor: const Color(0xFF085041),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9F2E7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF085041)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيتم إرسال دعوة للتابع عبر البريد الإلكتروني',
                          style: TextStyle(color: Color(0xFF085041)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    hintText: 'أدخل اسم التابع',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF6F6F6),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الاسم الكامل مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@email.com',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF6F6F6),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'البريد الإلكتروني مطلوب';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'صلة القرابة',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF6F6F6),
                  ),
                  value: _selectedRelationship,
                  items: _relationships.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['value'],
                      child: Text(item['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedRelationship = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'الرجاء اختيار العلاقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendInvitation,
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'إرسال الدعوة',
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
      ),
    );
  }
}