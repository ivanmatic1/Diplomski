import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MatchCard extends StatelessWidget {
  final String matchId;
  final String date;
  final String location;
  final String status; // "W", "L", "P"
  final String mode;   // npr. "2v2", "5v5"
  final VoidCallback onDetailsTap;

  const MatchCard({
    super.key,
    required this.matchId,
    required this.date,
    required this.location,
    required this.status,
    required this.mode,
    required this.onDetailsTap,
  });

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'W':
        return Colors.green;
      case 'L':
        return Colors.red;
      case 'P':
        return Colors.orange;
      default:
        return colorScheme.onSurface;
    }
  }

  String _getStatusText(String status, AppLocalizations loc) {
    switch (status) {
      case 'W':
        return loc.status_win;
      case 'L':
        return loc.status_loss;
      case 'P':
        return loc.status_pending;
      default:
        return loc.status_unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5);
    final borderColor = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5);
    final statusColor = _getStatusColor(status, colorScheme);
    final statusText = _getStatusText(status, loc);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                '${loc.match_id}: $matchId',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${loc.match_date}: $date',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${loc.match_location}: $location',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${loc.match_mode}: $mode',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onDetailsTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(loc.match_details_button),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(90),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
