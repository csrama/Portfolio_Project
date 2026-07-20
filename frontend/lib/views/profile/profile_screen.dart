import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dependent_provider.dart';
import '../settings/settings_screen.dart';
import '../dashboard/dependents_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../repositories/auth_repository.dart';
import '../../services/google_auth_service.dart';
import '../../i18n/strings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> _avatarPresets = [
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Aneka',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Jack',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Sophia',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Oliver',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=Mia',
  ];

  void _changeAvatar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Strings.tr(context, 'choose_avatar'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatarPresets.length,
                    itemBuilder: (context, index) {
                      final url = _avatarPresets[index];
                      return GestureDetector(
                        onTap: () {
                          context.read<AuthProvider>().updateProfile(
                                fullName: context
                                        .read<AuthProvider>()
                                        .user?['full_name'] ??
                                    context
                                        .read<AuthProvider>()
                                        .user?['name'] ??
                                    'مستخدم',
                                email: context
                                        .read<AuthProvider>()
                                        .user?['email'] ??
                                    '',
                                photoUrl: url,
                              );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(Strings.tr(
                                    context, 'avatar_changed_success'))),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey[200],
                            child: ClipOval(
                              child: Image.network(
                                url,
                                width: 70,
                                height: 75,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, size: 40),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(Strings.tr(context, 'custom_avatar_url')),
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomUrlDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomUrlDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Strings.tr(context, 'custom_url_title')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: Strings.tr(context, 'enter_url_hint'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Strings.tr(context, 'cancel')),
            ),
            TextButton(
              onPressed: () {
                final url = controller.text.trim();
                if (url.isNotEmpty) {
                  context.read<AuthProvider>().updateProfile(
                        fullName:
                            context.read<AuthProvider>().user?['full_name'] ??
                                context.read<AuthProvider>().user?['name'] ??
                                'مستخدم',
                        email:
                            context.read<AuthProvider>().user?['email'] ?? '',
                        photoUrl: url,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            Strings.tr(context, 'avatar_changed_success'))),
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

  void _editEmail() {
    final user = context.read<AuthProvider>().user;
    final controller = TextEditingController(text: user?['email'] ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Strings.tr(context, 'change_email_title')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: Strings.tr(context, 'email'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Strings.tr(context, 'cancel')),
            ),
            TextButton(
              onPressed: () {
                final email = controller.text.trim();
                if (email.isNotEmpty) {
                  context.read<AuthProvider>().updateProfile(
                        fullName: user?['full_name'] ?? user?['name'] ?? '',
                        email: email,
                        photoUrl: user?['photo'] ?? '',
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(Strings.tr(context, 'edit_email_success'))),
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
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? const Icon(Icons.person,
                                  size: 60, color: Color(0xFF085041))
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _changeAvatar,
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFF1D9E75),
                            child: Icon(Icons.camera_alt,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
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
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.email_outlined,
                              color: Color(0xFF085041)),
                          title: Text(Strings.tr(context, 'email')),
                          subtitle: Text(email),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Color(0xFF1D9E75)),
                            onPressed: _editEmail,
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
                                  builder: (_) => const DependentsScreen()),
                            );
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
                                  builder: (_) => const SettingsScreen()),
                            );
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
                          borderRadius: BorderRadius.circular(12),
                        ),
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
