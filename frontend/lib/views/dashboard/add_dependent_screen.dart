import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../i18n/strings.dart';

class AddDependentScreen extends StatefulWidget {
  const AddDependentScreen({super.key});

  @override
  State<AddDependentScreen> createState() => _AddDependentScreenState();
}

class _AddDependentScreenState extends State<AddDependentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedRelationship;
  bool _isLoading = false;
  String? _generatedLink;
  bool _linkCopied = false;
  final bool _inviteMode = true;

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
    super.dispose();
  }

  Future<void> _addDependent() async {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _nameController.text.trim();
    final relationship = _selectedRelationship;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.accessToken;

      if (token == null) {
        _showSnackBar(Strings.tr(context, 'please_login_first'), Colors.red);
        return;
      }

      final Map<String, dynamic> body = {
        'full_name': fullName,
        'relationship': relationship,
      };

      Map<String, dynamic> response;
      if (_inviteMode) {
        response = await ApiService.postJson(
          '/dependents',
          body: body,
          token: token,
        );
      } else {
        body['invite'] = false;
        response = await ApiService.postJson(
          '/dependents',
          body: body,
          token: token,
        );
      }

      if (response['success'] == true) {
        if (_inviteMode) {
          final data = response['data'] as Map<String, dynamic>? ?? {};
          final inviteLink = data['invite_link'] as String? ?? '';
          setState(() {
            _generatedLink = inviteLink;
            _linkCopied = false;
          });
          _showSnackBar(
            Strings.tr(context, 'invite_link_created'),
            const Color(0xFF085041),
          );
        } else {
          _showSnackBar(
            Strings.tr(context, 'dependent_added_success'),
            const Color(0xFF085041),
          );
        }
      } else {
        _showSnackBar(
          response['error'] ?? Strings.tr(context, 'operation_failed'),
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        '${Strings.tr(context, 'operation_failed')}: ${e.toString()}',
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_generatedLink != null && _generatedLink!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedLink!));
      setState(() => _linkCopied = true);
      _showSnackBar(
        Strings.tr(context, 'link_copied_message'),
        const Color(0xFF085041),
      );
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
        title: Text(Strings.tr(context, 'add_dependent_title')),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9F2E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF085041)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Strings.tr(context, 'invite_info'),
                        style: const TextStyle(color: Color(0xFF085041)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: Strings.tr(context, 'name_hint'),
                  hintText: Strings.tr(context, 'name_hint'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFFF6F6F6),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return Strings.tr(context, 'missing_data');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: Strings.tr(context, 'relationship_label'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFFF6F6F6),
                ),
                initialValue: _selectedRelationship,
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
                    return Strings.tr(context, 'missing_data');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              if (_generatedLink != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _linkCopied
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFF085041),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _linkCopied ? Icons.check_circle : Icons.link,
                            color: _linkCopied
                                ? const Color(0xFF1D9E75)
                                : const Color(0xFF085041),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _linkCopied
                                ? Strings.tr(context, 'link_copied')
                                : Strings.tr(context, 'invite_link_label'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _linkCopied
                                  ? const Color(0xFF1D9E75)
                                  : const Color(0xFF085041),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        _generatedLink!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF085041),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: Icon(
                            _linkCopied ? Icons.check : Icons.copy,
                            size: 18,
                          ),
                          label: Text(
                            _linkCopied
                                ? Strings.tr(context, 'link_copied')
                                : Strings.tr(context, 'copy_link'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF085041),
                            side: const BorderSide(color: Color(0xFF085041)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addDependent,
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
                      : Text(
                          Strings.tr(context, 'generate_invite_link'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              if (_generatedLink != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF085041),
                      side: const BorderSide(color: Color(0xFF085041)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      Strings.tr(context, 'back_to_list'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
