import 'package:flutter/material.dart';
import 'package:terminko/models/friend_model.dart';
import 'package:terminko/services/friends_list_service.dart';

class BlockedUserCard extends StatelessWidget {
  final FriendModel user;
  final VoidCallback onUnblocked;

  const BlockedUserCard({
    super.key,
    required this.user,
    required this.onUnblocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bgColor = isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(3);
    final borderColor = isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(5);

    final firstName = user.user.firstName;
    final lastName = user.user.lastName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$firstName $lastName',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                await unblockUser(user.id);
                onUnblocked();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withAlpha(15),
                ),
                child: Icon(Icons.lock_open, color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
