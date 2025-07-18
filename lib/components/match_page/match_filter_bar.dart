import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MatchFilterBar extends StatelessWidget {
  final List<String> sports;
  final String selectedSport;
  final bool recentFirst;
  final Function(String) onSportChanged;
  final Function(bool) onSortChanged;

  const MatchFilterBar({
    super.key,
    required this.sports,
    required this.selectedSport,
    required this.recentFirst,
    required this.onSportChanged,
    required this.onSortChanged,
  });

  String getLocalizedSportName(String key, AppLocalizations loc) {
    switch (key.toLowerCase()) {
      case 'football':
        return loc.football;
      case 'basketball':
        return loc.basketball;
      case 'padel':
        return loc.padel;
      case 'all':
        return loc.all_sports;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(40)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSport,
                dropdownColor: colorScheme.surface,
                iconEnabledColor: colorScheme.primary,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                onChanged: (value) {
                  if (value != null) onSportChanged(value);
                },
                items: sports.map((sport) {
                  return DropdownMenuItem(
                    value: sport,
                    child: Text(
                      getLocalizedSportName(sport, loc),
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Tooltip(
            message: recentFirst ? loc.newest_first : loc.oldest_first,
            child: IconButton(
              onPressed: () => onSortChanged(!recentFirst),
              icon: Icon(
                recentFirst ? Icons.arrow_downward : Icons.arrow_upward,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
