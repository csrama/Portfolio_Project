import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../i18n/strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsBody();
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

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
          _sectionTitle(context, Strings.tr(context, 'settings')),
          const SizedBox(height: 8),
          _languageRow(context, settings),
          const Divider(height: 24),
          _notificationRow(context, settings),
          const Divider(height: 24),
          _darkModeRow(context, settings),
          const Divider(height: 24),
          _myMedicationsRow(context),
          const Divider(height: 24),
          _myRemindersRow(context),
          const Divider(height: 24),
          _privacySection(context, settings),
          const Divider(height: 24),
          _aboutSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
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
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Strings.tr(context, 'email'),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 14,
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

Widget _sectionTitle(BuildContext context, String title) {
  return Text(
    title,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );
}

Widget _languageRow(BuildContext context, AppSettingsProvider settings) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final newLang = settings.languageCode == 'ar' ? 'en' : 'ar';
        context.read<AppSettingsProvider>().setLanguageCode(newLang);
      },
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
                  Text(
                    Strings.tr(context, 'language'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settings.languageCode == 'ar'
                        ? Strings.tr(context, 'arabic')
                        : Strings.tr(context, 'english'),
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF085041),
              size: 20,
            ),
          ],
        ),
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
                Text(
                  Strings.tr(context, 'notifications'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  settings.notificationsEnabled
                      ? Strings.tr(context, 'on')
                      : Strings.tr(context, 'off'),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.notificationsEnabled,
            onChanged: (v) =>
                context.read<AppSettingsProvider>().setNotificationsEnabled(v),
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
                Text(
                  Strings.tr(context, 'dark_mode'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  settings.darkModeEnabled
                      ? Strings.tr(context, 'enabled')
                      : Strings.tr(context, 'disabled'),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
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

Widget _myMedicationsRow(BuildContext context) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pop(context, {'navigateTo': 'medications'}),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.medication_outlined, color: Color(0xFF085041)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Strings.tr(context, 'my_medications'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Strings.tr(context, 'saved_medications'),
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF085041),
              size: 16,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _myRemindersRow(BuildContext context) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pop(context, {'navigateTo': 'reminders'}),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF085041),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Strings.tr(context, 'my_reminders'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Strings.tr(context, 'reminders'),
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF085041),
              size: 16,
            ),
          ],
        ),
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
              Text(
                Strings.tr(context, 'privacy'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  Strings.tr(context, 'track_usage'),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
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
              Text(
                Strings.tr(context, 'about'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Strings.tr(context, 'about_desc'),
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(Strings.tr(context, 'done'))),
              );
            },
            child: Text(Strings.tr(context, 'check_updates')),
          ),
        ],
      ),
    ),
  );
}
