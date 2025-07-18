import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/components/user_profile_page/edit_profile_page_segemnts.dart';
import 'package:terminko/models/user_model.dart';

class ProfileHeaderSection extends StatelessWidget {
  final UserModel user;
  final VoidCallback onProfileImageTap;

  const ProfileHeaderSection({
    super.key,
    required this.user,
    required this.onProfileImageTap,
  });

  void _openEditProfilePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePageSegments(
          user: user,
          onProfileImageTap: onProfileImageTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    final bgColor = isDark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(10);

    final borderColor = isDark
        ? Colors.white.withAlpha(38)
        : Colors.black.withAlpha(12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onProfileImageTap,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                        ? Icon(Icons.person, color: colorScheme.onPrimary)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openEditProfilePage(context),
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(loc.edit_button),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
