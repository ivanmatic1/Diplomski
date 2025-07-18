import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terminko/providers/theme_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ThemeToggleSection extends StatelessWidget {
  const ThemeToggleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final provider = Provider.of<ThemeProvider>(context);

    final bgColor = isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(3);
    final borderColor = isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.change_theme, style: theme.textTheme.titleMedium),
            Row(
              children: [
                Icon(Icons.light_mode, color: !isDark ? Colors.amber : Colors.grey),
                Switch(
                  value: isDark,
                  onChanged: (_) => provider.toggleTheme(),
                ),
                Icon(Icons.dark_mode, color: isDark ? Colors.blue : Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
