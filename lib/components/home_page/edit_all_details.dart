import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditAllDetails extends StatelessWidget {
  final List<String> positions;
  final String time;
  final int distanceKm;
  final VoidCallback onEdit;

  const EditAllDetails({
    super.key,
    required this.positions,
    required this.time,
    required this.distanceKm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5);
    final borderColor = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.quick_parameters, style: textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (positions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "${loc.positions_title}: ${positions.join(', ')}",
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              ),
            ),
          if (time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "${loc.preferred_time_title}: $time",
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "${loc.preferred_time_title}: –",
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(150)),
              ),
            ),
          Text(
            "${loc.selected_distance_label}: $distanceKm km",
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
