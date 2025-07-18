import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/components/user_profile_page/glass_segmented_tab_bar.dart';
import 'package:terminko/models/stat_model.dart';

class ProfileStatsSection extends StatefulWidget {
  final StatModel globalStats;
  final Map<String, StatModel> sportStats;
  final List<String> selectedSports;

  const ProfileStatsSection({
    super.key,
    required this.globalStats,
    required this.sportStats,
    required this.selectedSports,
  });

  @override
  State<ProfileStatsSection> createState() => _ProfileStatsSectionState();
}

class _ProfileStatsSectionState extends State<ProfileStatsSection> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final List<String> allTabs = [
      loc.global,
      ...widget.selectedSports.map((s) => _getLocalizedSportName(loc, s))
    ];

    final List<int> allCounts = List.filled(allTabs.length, 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassSegmentedTabBar(
          selectedIndex: selectedIndex,
          tabs: allTabs,
          counts: allCounts,
          onTabSelected: (index) {
            setState(() => selectedIndex = index);
          },
        ),
        const SizedBox(height: 12),
        _buildStatsCard(context, _getCurrentStats(), loc),
      ],
    );
  }

  StatModel _getCurrentStats() {
    if (selectedIndex == 0) {
      return widget.globalStats;
    } else {
      final key = widget.selectedSports[selectedIndex - 1];
      return widget.sportStats[key] ?? StatModel.empty();
    }
  }

  Widget _buildStatsCard(BuildContext context, StatModel stats, AppLocalizations loc) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(4);
    final borderColor = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8);

    final matches = stats.matchesPlayed.toString();
    final winRate = '${stats.winRate.toStringAsFixed(1)}%';
    final rating = stats.averageRating.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.statistics_title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, loc.matches_played, matches),
              _buildStatItem(context, loc.win_rate, winRate),
              _buildStatItem(context, loc.avg_rating, rating),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final textStyle = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: textStyle.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textStyle.bodySmall?.copyWith(
            color: colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ],
    );
  }

  String _getLocalizedSportName(AppLocalizations loc, String sportKey) {
    switch (sportKey.toLowerCase()) {
      case 'football':
        return loc.football;
      case 'basketball':
        return loc.basketball;
      case 'tennis':
      case 'padel':
        return loc.padel;
      default:
        return sportKey[0].toUpperCase() + sportKey.substring(1);
    }
  }
}
