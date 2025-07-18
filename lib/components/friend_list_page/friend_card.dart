import 'package:flutter/material.dart';
import 'package:terminko/services/friends_list_service.dart';
import 'package:terminko/models/friend_model.dart';

class FriendCard extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback? onInvite;
  final VoidCallback onRemoved;

  const FriendCard({
    super.key,
    required this.friend,
    required this.onRemoved,
    this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final user = friend.user;
    final bgColor = isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(3);
    final borderColor = isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage:
                  user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
              child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                  ? Text(
                      user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${user.firstName} ${user.lastName}',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (onInvite != null) ...[
              GestureDetector(
                onTap: onInvite,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.secondary.withAlpha(15),
                  ),
                  child: Icon(Icons.add, color: colorScheme.secondary),
                ),
              ),
              const SizedBox(width: 12),
            ],
            GestureDetector(
              onTap: () async {
                await removeFriend(user.id);
                onRemoved();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.error.withAlpha(15),
                ),
                child: Icon(Icons.close, color: colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
