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
  final _ageController = TextEditingController();
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
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _addDependent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fullName = _nameController.text.trim();
    final relationship = _selectedRelationship;

    if (fullName.isEmpty) {
      _showSnackBar('الاسم الكامل مطلوب', Colors.red);
      return;
    }

    if (relationship == null) {
      _showSnackBar('الرجاء اختيار العلاقة', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.accessToken;

      if (token == null) {
        _showSnackBar('الرجاء تسجيل الدخول أولاً', Colors.red);
        return;
      }

      // Convert age to approximate date of birth if provided
      String? dateOfBirth;
      final age = int.tryParse(_ageController.text.trim());
      if (age != null && age > 0) {
        final now = DateTime.now();
        dateOfBirth = DateTime(now.year - age, now.month, now.day)
            .toIso8601String();
      }

      final body = {
        'full_name': fullName,
        'relationship': relationship,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      };

      final response = await ApiService.postJson(
        '/dependents',
        body: body,
        token: token,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة التابع بنجاح'),
              backgroundColor: Color(0xFF085041),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        _showSnackBar(
          response['error'] ?? 'فشل إضافة التابع',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        'حدث خطأ: ${e.toString()}',
        Colors.red,
      );
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
        title: const Text('إضافة تابع جديد'),
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
                          'أدخل بيانات التابع لإضافته',
                          style: TextStyle(color: Color(0xFF085041)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // اسم التابع
                TextFormField(
                  controller: _nameController,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    hintText: 'أدخل اسم التابع',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF085041)),
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
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'العمر (اختياري)',
                    hintText: 'أدخل عمر التابع',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF085041)),
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'العلاقة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    prefixIcon: const Icon(Icons.family_restroom, color: Color(0xFF085041)),
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
                    onPressed: _isLoading ? null : _addDependent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF085041),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
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
                            'إضافة التابع',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'سيتم إضافة التابع وتتمكن من إدارة أدويته وجدوله.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
