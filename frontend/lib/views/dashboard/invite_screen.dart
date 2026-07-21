import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/dependent_service.dart';
import '../../services/api_service.dart';
import '../onboarding/onboarding_screen.dart';
import 'home_screen.dart';

class InviteScreen extends StatefulWidget {
  final String token;

  const InviteScreen({super.key, required this.token});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  Map<String, dynamic>? _inviteInfo;
  bool _accepted = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadInviteInfo();
  }

  Future<void> _loadInviteInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final info = await DependentService(apiService: ApiService())
          .getInviteInfo(widget.token);

      if (!mounted) return;
      setState(() {
        _inviteInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().contains('401')
            ? 'رابط الدعوة غير صالح أو منتهي الصلاحية'
            : e.toString().contains('410')
                ? 'انتهت صلاحية الدعوة'
                : 'تعذر تحميل معلومات الدعوة';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptInvite() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.accessToken;

      if (token == null) {
        // User is not logged in, redirect to login
        if (!mounted) return;
        final loggedIn = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const OnboardingScreen(),
          ),
        );

        if (loggedIn == true && mounted) {
          // Retry accept after login
          await _acceptInvite();
        } else {
          setState(() => _isProcessing = false);
        }
        return;
      }

      final response = await DependentService(apiService: ApiService())
          .acceptInvite(token, widget.token);

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _accepted = true;
          _isProcessing = false;
          _statusMessage = 'تم قبول الدعوة بنجاح! ';
        });
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = response['error'] ?? 'فشل قبول الدعوة';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = 'حدث خطأ: ${e.toString()}';
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
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
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF085041),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل معلومات الدعوة...',
            style: TextStyle(fontSize: 16, color: Color(0xFF085041)),
          ),
        ],
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.link_off,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInviteInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF085041),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_accepted) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Color(0xFF1D9E75),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage ?? 'تم قبول الدعوة بنجاح ',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF085041),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك الآن متابعة أدويتك من قبل مقدم الرعاية',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF085041),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'الذهاب للرئيسية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isProcessing) {
      return const Column(
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
      );
    }

    if (_statusMessage != null && !_accepted) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _acceptInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF085041),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'حاول مرة أخرى',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    // Show invite details
    final dependentName = _inviteInfo?['dependent_name'] ?? '';
    final relationship = _inviteInfo?['relationship'] ?? '';
    final caregiverName = _inviteInfo?['caregiver_name'] ?? '';

    String relationshipLabel = '';
    switch (relationship) {
      case 'spouse':
        relationshipLabel = 'زوج/زوجة';
        break;
      case 'child':
        relationshipLabel = 'ابن/ابنة';
        break;
      case 'parent':
        relationshipLabel = 'أب/أم';
        break;
      case 'sibling':
        relationshipLabel = 'أخ/أخت';
        break;
      case 'other':
        relationshipLabel = 'أخرى';
        break;
      default:
        relationshipLabel = relationship;
    }

    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFD9F2E7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.mail_outline,
              color: Color(0xFF085041),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'دعوة للانضمام',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF085041),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caregiverName.isNotEmpty) ...[
                  _buildInfoRow(
                    'مقدم الرعاية',
                    caregiverName,
                    Icons.person,
                  ),
                  const SizedBox(height: 12),
                ],
                if (dependentName.isNotEmpty) ...[
                  _buildInfoRow(
                    'اسم التابع',
                    dependentName,
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                ],
                if (relationshipLabel.isNotEmpty)
                  _buildInfoRow(
                    'صلة القرابة',
                    relationshipLabel,
                    Icons.family_restroom,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'هل ترغب في قبول الدعوة؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),

          if (isLoggedIn) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'رفض',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _acceptInvite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF085041),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'قبول الدعوة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Login prompt for non-logged-in user
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final loggedIn = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnboardingScreen(),
                    ),
                  );
                  if (loggedIn == true && mounted) {
                    // User logged in, show the accept UI again
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF085041),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'تسجيل الدخول لقبول الدعوة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'العودة',
                style: TextStyle(
                  color: Color(0xFF085041),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF085041)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF085041),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

