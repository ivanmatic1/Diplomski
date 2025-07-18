import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:terminko/services/firestore_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  Future<String> _getUserFirstName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return '';
    final user = await getUserById(uid);
    return user?.firstName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: _getUserFirstName(),
      builder: (context, snapshot) {
        final name = snapshot.data ?? '';

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Center(
            child: Column(
              children: [
                Text(
                  loc.welcome,
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme.onSurface.withAlpha(60),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name.isNotEmpty ? name : '...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
