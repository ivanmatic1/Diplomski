import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SportSelectionTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<String> tabs;
  final void Function(int) onTabSelected;
  final void Function(String sport, bool selected) onToggleSport;

  const SportSelectionTabBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabSelected,
    required this.onToggleSport,
  });

  String _getLocalizedLabel(String key, AppLocalizations loc) {
    switch (key) {
      case 'football':
        return loc.football;
      case 'basketball':
        return loc.basketball;
      case 'padel':
        return loc.padel;
      default:
        return key;
    }
  }

  void _showSportDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final sports = ['football', 'basketball', 'padel'];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(loc.select_sport_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: sports.map((sport) {
              final isSelected = tabs.contains(sport);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (val) {
                  Navigator.of(ctx).pop();
                  onToggleSport(sport, val ?? false);
                },
                title: Text(_getLocalizedLabel(sport, loc)),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4);
    final borderColor = theme.colorScheme.onSurface.withAlpha(20);
    final activeColor = theme.colorScheme.primary;

    final allTabs = [...tabs, '+'];

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
            children: List.generate(allTabs.length, (index) {
              final isAddButton = index == allTabs.length - 1;
              final isActive = index == selectedIndex && !isAddButton;

              return GestureDetector(
                onTap: () {
                  if (isAddButton) {
                    _showSportDialog(context);
                  } else {
                    onTabSelected(index);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isAddButton ? '+' : _getLocalizedLabel(tabs[index], loc),
                    style: TextStyle(
                      color: isActive ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
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
