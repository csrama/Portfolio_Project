import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class InviteScreen extends StatefulWidget {
  final String token;

  const InviteScreen({super.key, required this.token});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _isProcessing = false;
  String? _statusMessage;
  bool? _isAccepted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInvitationDialog();
    });
  }

  Future<void> _showInvitationDialog() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.mail_outline, color: Color(0xFF085041), size: 28),
            SizedBox(width: 8),
            Text('دعوة للانضمام'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم إرسال دعوة لك للانضمام كتابع.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'هل ترغب في قبول الدعوة؟',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF085041),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleInviteResponse(false);
            },
            child: const Text(
              'رفض',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleInviteResponse(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF085041),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'قبول',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleInviteResponse(bool accept) async {
    setState(() {
      _isProcessing = true;
      _isAccepted = accept;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.accessToken;

      if (token == null) {
        _showResult(
          false,
          'الرجاء تسجيل الدخول أولاً',
          Icons.error,
          Colors.red,
        );
        return;
      }

      if (accept) {
        final response = await ApiService.postJson(
          '/dependents/invite/${widget.token}/accept',
          body: {},
          token: token,
        );

        if (response['success'] == true) {
          _showResult(
            true,
            'تم قبول الدعوة بنجاح! ',
            Icons.check_circle,
            const Color(0xFF085041),
          );
        } else {
          _showResult(
            false,
            response['error'] ?? 'فشل قبول الدعوة',
            Icons.error,
            Colors.red,
          );
        }
      } else {
        _showResult(
          false,
          'تم رفض الدعوة',
          Icons.cancel,
          Colors.orange,
        );
      }
    } catch (e) {
      _showResult(
        false,
        'حدث خطأ: ${e.toString()}',
        Icons.error,
        Colors.red,
      );
    }
  }

  void _showResult(bool success, String message, IconData icon, Color color) {
    setState(() {
      _isProcessing = false;
      _statusMessage = message;
    });

    showDialog(
      context: context,
      barrierDismissible: success,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              success ? 'تم بنجاح' : 'فشل',
              style: TextStyle(color: color),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (success) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            child: Text(
              success ? 'الذهاب للرئيسية' : 'حاول مرة أخرى',
              style: TextStyle(
                color: success ? const Color(0xFF085041) : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Center(
            child: _isProcessing
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF085041),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'جاري معالجة الطلب...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  )
                : _statusMessage != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isAccepted == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 80,
                            color: _isAccepted == true
                                ? const Color(0xFF085041)
                                : Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _statusMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}