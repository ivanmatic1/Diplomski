import 'package:flutter/material.dart';
import 'package:terminko/components/match_page/match_card.dart';
import 'package:terminko/components/match_page/match_filter_bar.dart';
import 'package:terminko/components/match_page/match_details_page.dart';
import 'package:terminko/models/match_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/services/match_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  String selectedSport = 'all';
  bool recentFirst = true;
  List<MatchModel> matches = [];
  bool isLoading = true;

  final List<String> availableSports = ['all', 'football', 'basketball', 'padel'];

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }

  Future<void> fetchMatches() async {
    setState(() => isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final matchService = MatchService();
    final fetched = await matchService.fetchMatches(
      sport: selectedSport,
      recentFirst: recentFirst,
    );

    setState(() {
      matches = fetched;
      isLoading = false;
    });
  }

  String _formatDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMMd(locale).add_Hm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(loc.your_matches),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: MatchFilterBar(
              sports: availableSports,
              selectedSport: selectedSport,
              recentFirst: recentFirst,
              onSportChanged: (value) {
                setState(() => selectedSport = value);
                fetchMatches();
              },
              onSortChanged: (value) {
                setState(() => recentFirst = value);
                fetchMatches();
              },
            ),
          ),
          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text(
                loc.no_matches_found,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final status = match.statusMap[currentUserId] ?? 'P';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child:MatchCard(
                      matchId: match.id,
                      date: _formatDate(match.time, context),
                      location: match.location,
                      status: status,
                      mode: match.mode,
                      onDetailsTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchDetailsPage(
                              match: match,
                              currentUserId: currentUserId!,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 