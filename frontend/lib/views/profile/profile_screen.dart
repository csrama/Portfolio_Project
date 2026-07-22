import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../settings/settings_screen.dart';
import '../dashboard/dependents_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../repositories/auth_repository.dart';
import '../../services/google_auth_service.dart';
import '../../i18n/strings.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const ProfileScreen({super.key, this.onNavigateToTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _editName() {
    final user = context.read<AuthProvider>().user;
    final controller =
        TextEditingController(text: user?['full_name'] ?? user?['name'] ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Strings.tr(context, 'edit_full_name_title')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: Strings.tr(context, 'full_name'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Strings.tr(context, 'cancel')),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  context.read<AuthProvider>().updateProfile(
                        fullName: name,
                        email: user?['email'] ?? '',
                        photoUrl: user?['photo'] ?? '',
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(Strings.tr(context, 'edit_name_success'))),
                  );
                }
              },
              child: Text(Strings.tr(context, 'save')),
            ),
          ],
        );
      },
    );
  }

  void _showAdherenceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<dynamic>(
              future: () async {
                final authProvider = context.read<AuthProvider>();
                final token = authProvider.accessToken;
                if (token == null) return null;
                return ApiService.getJsonDynamic('/adherence/rate',
                    token: token);
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data;
                if (data == null || data is! Map) {
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('تعذر جلب بيانات متابعة الجرعات',
                          textAlign: TextAlign.center),
                    ),
                  );
                }

                final rate = data['adherence_rate'] ?? 0;
                final completed = data['completed'] ?? 0;
                final total = data['total'] ?? 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('متابعة الجرعات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text('$rate%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF085041))),
                    const SizedBox(height: 4),
                    const Text('نسبة الالتزام بالجرعات',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('$completed',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('جرعات مأخوذة',
                                style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('$total',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('إجمالي الجرعات',
                                style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    await AuthRepository().clearSession();
    await GoogleAuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final name = user?['full_name'] ?? user?['name'] ?? 'مستخدم';
    final email = user?['email'] ?? 'لا يوجد بريد إلكتروني';
    final photoUrl = user?['photo'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF085041),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(top: 40, bottom: 30),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 60, color: Color(0xFF085041))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline,
                              color: Color(0xFF085041)),
                          title: Text(Strings.tr(context, 'full_name')),
                          subtitle: Text(name),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Color(0xFF1D9E75)),
                            onPressed: _editName,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('الميزات',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF085041))),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.medication_outlined,
                              color: Color(0xFF085041)),
                          title: Text('أدويتي'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            widget.onNavigateToTab?.call(1);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined,
                              color: Color(0xFF085041)),
                          title: Text('تذكيراتي'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            widget.onNavigateToTab?.call(2);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.fact_check_outlined,
                              color: Color(0xFF085041)),
                          title: Text('متابعة الجرعات'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _showAdherenceSheet();
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.people_outline,
                              color: Color(0xFF085041)),
                          title: Text(
                              Strings.tr(context, 'dependents_management')),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DependentsScreen()));
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined,
                              color: Color(0xFF085041)),
                          title: Text(Strings.tr(context, 'settings')),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(Strings.tr(context, 'logout'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
