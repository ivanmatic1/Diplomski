import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.05);
    final iconColorActive = isDark ? Colors.white : Colors.black;
    final iconColorInactive = isDark ? Colors.white70 : Colors.black45;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(context, LucideIcons.users, 0, iconColorActive, iconColorInactive),
                _buildNavItem(context, LucideIcons.calendarClock, 1, iconColorActive, iconColorInactive),
                _buildNavItem(context, LucideIcons.home, 2, iconColorActive, iconColorInactive),
                _buildNavItem(context, LucideIcons.user, 3, iconColorActive, iconColorInactive),
                _buildNavItem(context, LucideIcons.settings, 4, iconColorActive, iconColorInactive),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index, Color active, Color inactive) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Icon(
        icon,
        size: 28,
        color: index == currentIndex ? active : inactive,
      ),
    );
  }
}
