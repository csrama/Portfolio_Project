import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../i18n/strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsBody();
  }
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody();

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  void _editName(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final name = user?['full_name'] ?? user?['name'] ?? 'مستخدم';
    final email = user?['email'] ?? 'لا يوجد بريد إلكتروني';

    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.tr(context, 'settings')),
        backgroundColor: const Color(0xFF085041),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _userInfoCard(context, name, email),
          const SizedBox(height: 16),
          _sectionTitle(Strings.tr(context, 'settings')),
          const SizedBox(height: 8),
          _languageRow(context, settings),
          const Divider(height: 24),
          _notificationRow(context, settings),
          const Divider(height: 24),
          _darkModeRow(context, settings),
          const Divider(height: 24),
          _privacySection(context, settings),
          const Divider(height: 24),
          _aboutSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _userInfoCard(BuildContext context, String name, String email) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF085041),
              child: const Icon(Icons.person, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _editName(context),
                        child: const Icon(Icons.edit,
                            color: Color(0xFF1D9E75), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Strings.tr(context, 'email'),
                    style: const TextStyle(color: Colors.black38, fontSize: 12),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _languageRow(BuildContext context, AppSettingsProvider settings) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.language, color: Color(0xFF085041)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Strings.tr(context, 'language'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    settings.languageCode == 'ar'
                        ? Strings.tr(context, 'arabic')
                        : Strings.tr(context, 'english'),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            DropdownButton<String>(
              value: settings.languageCode,
              items: [
                DropdownMenuItem(
                    value: 'ar', child: Text(Strings.tr(context, 'arabic'))),
                DropdownMenuItem(
                    value: 'en', child: Text(Strings.tr(context, 'english'))),
              ],
              onChanged: (value) {
                if (value == null) return;
                context.read<AppSettingsProvider>().setLanguageCode(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationRow(BuildContext context, AppSettingsProvider settings) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.notifications, color: Color(0xFF085041)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Strings.tr(context, 'notifications'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    settings.notificationsEnabled
                        ? Strings.tr(context, 'on')
                        : Strings.tr(context, 'off'),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Switch(
              value: settings.notificationsEnabled,
              onChanged: (v) => context
                  .read<AppSettingsProvider>()
                  .setNotificationsEnabled(v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _darkModeRow(BuildContext context, AppSettingsProvider settings) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.dark_mode, color: Color(0xFF085041)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Strings.tr(context, 'dark_mode'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    settings.darkModeEnabled
                        ? Strings.tr(context, 'enabled')
                        : Strings.tr(context, 'disabled'),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Switch(
              value: settings.darkModeEnabled,
              onChanged: (v) =>
                  context.read<AppSettingsProvider>().setDarkModeEnabled(v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacySection(BuildContext context, AppSettingsProvider settings) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.privacy_tip, color: Color(0xFF085041)),
                const SizedBox(width: 12),
                Text(Strings.tr(context, 'privacy'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    Strings.tr(context, 'track_usage'),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                Switch(
                  value: settings.allowTracking,
                  onChanged: (v) =>
                      context.read<AppSettingsProvider>().setAllowTracking(v),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(Strings.tr(context, 'privacy_placeholder')),
                  ),
                );
              },
              child: Text(Strings.tr(context, 'view_privacy_policy')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF085041)),
                const SizedBox(width: 12),
                Text(Strings.tr(context, 'about'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              Strings.tr(context, 'about_desc'),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(Strings.tr(context, 'done'))),
                );
              },
              child: Text(Strings.tr(context, 'check_updates')),
            )
          ],
        ),
      ),
    );
  }
}
