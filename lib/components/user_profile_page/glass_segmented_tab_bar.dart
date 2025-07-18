import 'package:flutter/material.dart';

class GlassSegmentedTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<String> tabs;
  final List<int> counts;
  final void Function(int) onTabSelected;

  const GlassSegmentedTabBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.counts,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4);
    final borderColor = theme.colorScheme.onSurface.withAlpha(20);
    final activeColor = theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(tabs.length, (index) {
              final isActive = index == selectedIndex;
              return GestureDetector(
                onTap: () => onTabSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        tabs[index],
                        style: TextStyle(
                          color: isActive ? Colors.white : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: isActive
                            ? Colors.white.withAlpha(20)
                            : theme.colorScheme.onSurface.withAlpha(10),
                        child: Text(
                          counts[index].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
