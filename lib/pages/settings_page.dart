import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:terminko/components/settings_page/theme_toggle_section.dart';
import 'package:terminko/components/settings_page/language_select_section.dart';
import 'package:terminko/components/settings_page/faq_section.dart';
import 'package:terminko/components/settings_page/logout_section.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.logout)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(loc.profile),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80, top: 12),
          children: [
            const LanguageSection(),
            const ThemeToggleSection(),
            const FAQSection(),
            LogoutSection(onLogout: () => _handleLogout(context)),
          ],
        ),
      ),
    );
  }
}
