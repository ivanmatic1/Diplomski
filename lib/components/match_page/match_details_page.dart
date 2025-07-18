import 'package:flutter/material.dart';
import 'package:terminko/models/match_model.dart';
import 'package:terminko/models/user_model.dart';
import 'package:terminko/services/firestore_service.dart';
import 'package:terminko/services/rating_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:terminko/models/rating_model.dart';
import 'package:terminko/services/friends_list_service.dart';

class MatchDetailsPage extends StatefulWidget {
  final MatchModel match;
  final String currentUserId;

  const MatchDetailsPage({
    super.key,
    required this.match,
    required this.currentUserId,
  });

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  Map<String, UserModel> _playersData = {};
  Map<String, bool> _hasRated = {};
  bool _isLoadingPlayers = true;

  @override
  void initState() {
    super.initState();
    _loadPlayersData().then((_) => _checkRatings());
  }

  Future<void> _loadPlayersData() async {
    final allPlayerIds = {...widget.match.team1, ...widget.match.team2}.toList();

    final futures = allPlayerIds.map((id) => getUserById(id));
    final users = await Future.wait(futures);

    final Map<String, UserModel> loaded = {};
    for (int i = 0; i < allPlayerIds.length; i++) {
      if (users[i] != null) {
        loaded[allPlayerIds[i]] = users[i]!;
      }
    }

    if (mounted) {
      setState(() {
        _playersData = loaded;
        _isLoadingPlayers = false;
      });
    }
  }

  Future<void> _checkRatings() async {
    final matchId = widget.match.id;
    final currentUserId = widget.currentUserId;

    final allPlayerIds = {...widget.match.team1, ...widget.match.team2};

    for (var playerId in allPlayerIds) {
      bool rated = await hasAlreadyRated(matchId, currentUserId, playerId);
      _hasRated[playerId] = rated;
    }

    if (mounted) setState(() {});
  }

  void _showRatingDialog(String playerId) {
    final loc = AppLocalizations.of(context)!;
    double rating = 3;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.rate_player),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_playersData[playerId]?.firstName ?? ''),
                Slider(
                  min: 1,
                  max: 5,
                  divisions: 4,
                  value: rating,
                  label: rating.toStringAsFixed(0),
                  onChanged: (val) => setState(() => rating = val),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              await submitRating(
                RatingModel(
                  matchId: widget.match.id,
                  raterId: widget.currentUserId,
                  rateeId: playerId,
                  value: rating,
                ),
              );

              setState(() {
                _hasRated[playerId] = true;
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.rating_submitted)),
              );
            },
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  void _showFriendOptionsDialog(String playerId) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.player_options),
        content: Text('${_playersData[playerId]?.firstName ?? ''} ${_playersData[playerId]?.lastName ?? ''}'),
        actions: [
          TextButton(
            onPressed: () async {
              await sendFriendRequest(playerId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.friend_request_sent)),
              );
            },
            child: Text(loc.add_friend),
          ),
          TextButton(
            onPressed: () async {
              await blockUser(playerId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.user_blocked)),
              );
            },
            child: Text(loc.block_user),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(String playerId) {
    final loc = AppLocalizations.of(context)!;
    final user = _playersData[playerId];
    final isCurrentUser = playerId == widget.currentUserId;
    final alreadyRated = _hasRated[playerId] ?? false;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(user != null ? "${user.firstName} ${user.lastName}" : playerId),
      trailing: isCurrentUser || alreadyRated
          ? null
          : IconButton(
              icon: const Icon(Icons.star_border),
              tooltip: loc.rate_player,
              onPressed: () => _showRatingDialog(playerId),
            ),
      onTap: isCurrentUser ? null : () => _showFriendOptionsDialog(playerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoadingPlayers) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.match_details_button)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.match_details_button)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(loc.your_team, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...widget.match.team1.map(_buildPlayerTile),
          const SizedBox(height: 24),
          Text(loc.opponent_team, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...widget.match.team2.map(_buildPlayerTile),
        ],
      ),
    );
  }
}
