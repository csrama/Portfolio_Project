import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/dependent_service.dart';
import '../../services/api_service.dart';
import '../onboarding/onboarding_screen.dart';
import 'home_screen.dart';
import '../../i18n/strings.dart';

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
            ? Strings.tr(context, 'invite_invalid')
            : e.toString().contains('410')
                ? Strings.tr(context, 'invite_expired')
                : Strings.tr(context, 'invite_load_failed');
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
        if (!mounted) return;
        final loggedIn = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const OnboardingScreen(),
          ),
        );

        if (loggedIn == true && mounted) {
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
          _statusMessage = Strings.tr(context, 'invite_accepted');
        });
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage =
              response['error']?.toString() ??
              Strings.tr(context, 'invite_accept_failed');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '${Strings.tr(context, 'invite_error')}${e.toString()}';
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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF085041),
          ),
          const SizedBox(height: 16),
          Text(
            Strings.tr(context, 'invite_loading'),
            style: const TextStyle(fontSize: 16, color: Color(0xFF085041)),
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
              child: Text(
                Strings.tr(context, 'retry'),
                style: const TextStyle(color: Colors.white),
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
              _statusMessage ?? Strings.tr(context, 'invite_accepted'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF085041),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Strings.tr(context, 'invite_can_track'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
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
              child: Text(
                Strings.tr(context, 'invite_go_home'),
                style: const TextStyle(
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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF085041),
          ),
          const SizedBox(height: 16),
          Text(
            Strings.tr(context, 'invite_processing'),
            style: const TextStyle(fontSize: 16),
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
              child: Text(
                Strings.tr(context, 'invite_retry'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final dependentName = _inviteInfo?['dependent_name'] ?? '';
    final relationship = _inviteInfo?['relationship'] ?? '';
    final caregiverName = _inviteInfo?['caregiver_name'] ?? '';

    String relationshipLabel = '';
    switch (relationship) {
      case 'spouse':
        relationshipLabel = Strings.tr(context, 'spouse');
        break;
      case 'child':
        relationshipLabel = Strings.tr(context, 'child');
        break;
      case 'parent':
        relationshipLabel = Strings.tr(context, 'parent');
        break;
      case 'sibling':
        relationshipLabel = Strings.tr(context, 'sibling');
        break;
      case 'other':
        relationshipLabel = Strings.tr(context, 'other');
        break;
      default:
        relationshipLabel = relationship.toString();
    }

    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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

          Text(
            Strings.tr(context, 'invite_title'),
            style: const TextStyle(
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
                if (caregiverName.toString().isNotEmpty) ...[
                  _buildInfoRow(
                    Strings.tr(context, 'invite_caregiver'),
                    caregiverName.toString(),
                    Icons.person,
                  ),
                  const SizedBox(height: 12),
                ],
                if (dependentName.toString().isNotEmpty) ...[
                  _buildInfoRow(
                    Strings.tr(context, 'invite_dependent_name'),
                    dependentName.toString(),
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                ],
                if (relationshipLabel.isNotEmpty)
                  _buildInfoRow(
                    Strings.tr(context, 'relationship_label'),
                    relationshipLabel,
                    Icons.family_restroom,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            Strings.tr(context, 'invite_accept_question'),
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
                    child: Text(
                      Strings.tr(context, 'reject'),
                      style: const TextStyle(
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
                    child: Text(
                      Strings.tr(context, 'accept_invite'),
                      style: const TextStyle(
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
                child: Text(
                  Strings.tr(context, 'login_to_accept'),
                  style: const TextStyle(
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
              child: Text(
                Strings.tr(context, 'back'),
                style: const TextStyle(
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

