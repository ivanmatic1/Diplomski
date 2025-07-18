import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_entry_model.dart';
import '../models/match_model.dart';

class MatchmakingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, Map<String, dynamic>> footballModes = {
    '4+1': {'total': 10, 'perTeam': 5, 'goalkeeperRequired': true},
    '5v5': {'total': 10, 'perTeam': 5, 'goalkeeperRequired': false},
    '5+1': {'total': 12, 'perTeam': 6, 'goalkeeperRequired': true},
    '6v6': {'total': 12, 'perTeam': 6, 'goalkeeperRequired': false},
  };

  Future<void> processQueueForSport(String sportId) async {
    final queueSnapshot = await _firestore
        .collection('queueEntries')
        .where('sportId', isEqualTo: sportId)
        .where('status', isNull: true)
        .get();

    final List<QueueEntryModel> queue = queueSnapshot.docs
        .map((doc) => QueueEntryModel.fromMap(doc.id, doc.data()))
        .toList();

    final Map<String, List<QueueEntryModel>> timeGroups = {};
    for (final entry in queue) {
      for (final time in entry.availableTimes) {
        timeGroups.putIfAbsent(time, () => []).add(entry);
      }
    }

    for (final time in timeGroups.keys) {
      final List<QueueEntryModel> group = timeGroups[time]!;
      final match = await _tryFormMatch(group, sportId, time);
      if (match != null) {
        await _firestore.collection('pendingMatches').doc(match.id).set(match.toMap());

        for (final uid in [...match.team1, ...match.team2]) {
          await _firestore.collection('queueEntries').doc('$uid-$sportId').update({
            'proposedMatchId': match.id,
            'status': 'pending',
          });
        }
        break;
      }
    }
  }

  Future<void> confirmMatchIfAllReady(String matchId, String sportId) async {
    final snapshot = await _firestore
        .collection('queueEntries')
        .where('proposedMatchId', isEqualTo: matchId)
        .get();

    final entries = snapshot.docs;

    final allConfirmed = entries.every((doc) => doc['status'] == 'confirmed');
    final anyDeclined = entries.any((doc) => doc['status'] == 'declined');

    if (anyDeclined) {
      for (final doc in entries) {
        await doc.reference.update({
          'status': FieldValue.delete(),
          'proposedMatchId': FieldValue.delete(),
        });
      }
      await _firestore.collection('pendingMatches').doc(matchId).delete();
      return;
    }

    if (allConfirmed) {
      final matchDoc = await _firestore.collection('pendingMatches').doc(matchId).get();
      if (matchDoc.exists) {
        final match = MatchModel.fromMap(matchDoc.id, matchDoc.data()!);
        await _firestore.collection('matches').doc(matchId).set(match.toMap());

        for (final doc in entries) {
          await doc.reference.delete();
        }
        await _firestore.collection('pendingMatches').doc(matchId).delete();
      }
    }
  }


  Future<MatchModel?> _tryFormMatch(List<QueueEntryModel> group, String sportId, String time) async {
    switch (sportId) {
      case 'padel':
        return await _formPadelMatch(group, time);
      case 'football':
        return await _formFootballMatch(group, time);
      case 'basketball':
        return await _formBasketballMatch(group, time);
      default:
        return null;
    }
  }

  Future<MatchModel?> _formBasketballMatch(List<QueueEntryModel> group, String time) async {
    final modes = {
      '3v3': 6,
      '5v5': 10,
    };

    for (final mode in modes.keys) {
      final totalPlayers = modes[mode]!;
      final perTeam = totalPlayers ~/ 2;

      final candidates = group.where((e) => e.mode == mode).toList();
      if (candidates.length < totalPlayers) continue;

      final partyMap = _groupByParty(candidates);
      final soloPlayers = partyMap[null] ?? [];
      final List<List<QueueEntryModel>> parties = [];

      partyMap.forEach((partyId, entries) {
        if (partyId != null && entries.length <= perTeam) {
          parties.add(entries);
        }
      });

      final all = [...soloPlayers];
      for (final party in parties) {
        all.addAll(party);
      }

      for (int i = 0; i <= all.length - totalPlayers; i++) {
        final subset = all.sublist(i, i + totalPlayers);
        final team1 = subset.sublist(0, perTeam);
        final team2 = subset.sublist(perTeam);

        final venue = await _selectClosestVenue(subset, sport: 'basketball');
        if (venue != null) {
          final id = _firestore.collection('matches').doc().id;
          return MatchModel(
            id: id,
            time: DateTime.now(),
            location: venue['name'] ?? '',
            venueId: venue['id'],
            sport: 'basketball',
            mode: mode,
            team1: team1.map((e) => e.userId).toList(),
            team2: team2.map((e) => e.userId).toList(),
            statusMap: {
              for (var e in subset) e.userId: 'pending',
            },
            createdAt: DateTime.now(),
          );
        }
      }
    }

    return null;
  }


  Future<MatchModel?> _formFootballMatch(List<QueueEntryModel> group, String time) async {
    for (final mode in footballModes.keys) {
      final rules = footballModes[mode]!;
      final totalPlayers = rules['total'] as int;
      final players = group.where((e) => e.mode == mode).toList();

      if (players.length < totalPlayers) continue;

      final partyMap = _groupByParty(players);
      final soloPlayers = partyMap[null] ?? [];
      final List<List<QueueEntryModel>> parties = [];

      partyMap.forEach((partyId, entries) {
        if (partyId != null && entries.length <= rules['perTeam']) {
          parties.add(entries);
        }
      });

      final allCandidates = [...soloPlayers];
      for (final party in parties) {
        allCandidates.addAll(party);
      }

      for (int i = 0; i <= allCandidates.length - totalPlayers; i++) {
        final candidateGroup = allCandidates.sublist(i, i + totalPlayers);
        final validTeams = _splitFootballTeams(candidateGroup, rules['perTeam'], rules['goalkeeperRequired']);
        if (validTeams != null) {
          final venue = await _selectClosestVenue(candidateGroup, sport: 'football');
          if (venue != null) {
            final id = _firestore.collection('matches').doc().id;
            return _buildFootballMatchModel(id, validTeams[0], validTeams[1], venue, time, mode);
          }
        }
      }
    }

    return null;
  }

  List<List<QueueEntryModel>>? _splitFootballTeams(List<QueueEntryModel> players, int perTeam, bool goalkeeperRequired) {
    for (int i = 0; i <= players.length - perTeam; i++) {
      final team1 = players.sublist(i, i + perTeam);
      final team2 = players.where((p) => !team1.contains(p)).toList();
      if (team2.length != perTeam) continue;

      if (_validFootballTeam(team1, goalkeeperRequired) && _validFootballTeam(team2, goalkeeperRequired)) {
        return [team1, team2];
      }
    }
    return null;
  }

  bool _validFootballTeam(List<QueueEntryModel> team, bool goalkeeperRequired) {
    if (!goalkeeperRequired) return true;
    return team.any((p) => p.position == 'goalkeeper' || p.position == 'flex');
  }

  MatchModel _buildFootballMatchModel(
    String id,
    List<QueueEntryModel> team1,
    List<QueueEntryModel> team2,
    Map<String, dynamic> venue,
    String time,
    String mode,
  ) {
    final players = [...team1, ...team2];
    return MatchModel(
      id: id,
      time: DateTime.now(),
      location: venue['name'] ?? '',
      venueId: venue['id'],
      sport: 'football',
      mode: mode,
      team1: team1.map((e) => e.userId).toList(),
      team2: team2.map((e) => e.userId).toList(),
      statusMap: {
        for (var e in players) e.userId: 'pending',
      },
      createdAt: DateTime.now(),
    );
  }

  Future<MatchModel?> _formPadelMatch(List<QueueEntryModel> group, String time) async {
    final partyMap = _groupByParty(group);
    final List<QueueEntryModel> soloPlayers = partyMap[null] ?? [];
    final List<List<QueueEntryModel>> parties = [];

    partyMap.forEach((partyId, entries) {
      if (partyId != null && entries.length == 2) {
        parties.add(entries);
      }
    });

    for (int i = 0; i < parties.length - 1; i++) {
      for (int j = i + 1; j < parties.length; j++) {
        final team1 = parties[i];
        final team2 = parties[j];
        if (_validPadelTeam(team1) && _validPadelTeam(team2)) {
          final all = [...team1, ...team2];
          final venue = await _selectClosestVenue(all);
          if (venue != null) {
            final id = _firestore.collection('matches').doc().id;
            return _buildMatchModel(id, team1, team2, venue, time);
          }
        }
      }
    }

    for (final party in parties) {
      for (int i = 0; i < soloPlayers.length - 1; i++) {
        for (int j = i + 1; j < soloPlayers.length; j++) {
          final List<QueueEntryModel> others = [soloPlayers[i], soloPlayers[j]];

          if (_validPadelTeam(party) && _validPadelTeam(others)) {
            final all = [...party, ...others];
            final venue = await _selectClosestVenue(all);
            if (venue != null) {
              final id = _firestore.collection('matches').doc().id;
              return _buildMatchModel(id, party, others, venue, time);
            }
          }

          if (_validPadelTeam(others) && _validPadelTeam(party)) {
            final all = [...others, ...party];
            final venue = await _selectClosestVenue(all);
            if (venue != null) {
              final id = _firestore.collection('matches').doc().id;
              return _buildMatchModel(id, others, party, venue, time);
            }
          }
        }
      }
    }

    for (int i = 0; i < soloPlayers.length - 3; i++) {
      for (int j = i + 1; j < soloPlayers.length - 2; j++) {
        for (int k = j + 1; k < soloPlayers.length - 1; k++) {
          for (int l = k + 1; l < soloPlayers.length; l++) {
            final combo = [soloPlayers[i], soloPlayers[j], soloPlayers[k], soloPlayers[l]];
            final validTeams = _formPadelTeams(combo);
            if (validTeams != null) {
              final venue = await _selectClosestVenue(combo);
              if (venue != null) {
                final id = _firestore.collection('matches').doc().id;
                return _buildMatchModel(id, validTeams[0], validTeams[1], venue, time);
              }
            }
          }
        }
      }
    }

    return null;
  }

  List<List<QueueEntryModel>>? _formPadelTeams(List<QueueEntryModel> players) {
    final perms = [
      [0, 1, 2, 3],
      [0, 2, 1, 3],
      [0, 3, 1, 2]
    ];

    for (var p in perms) {
      final team1 = [players[p[0]], players[p[1]]];
      final team2 = [players[p[2]], players[p[3]]];

      if (_validPadelTeam(team1) && _validPadelTeam(team2)) {
        return [team1, team2];
      }
    }
    return null;
  }

  bool _validPadelTeam(List<QueueEntryModel> team) {
    final pos = team.map((e) => e.position).toList();
    if (pos.contains('Flexible')) return true;
    return (pos.contains('Left Side') && pos.contains('Right Side'));
  }

  Future<Map<String, dynamic>?> _selectClosestVenue(List<QueueEntryModel> players, {String sport = 'padel'}) async {
    final fieldName = sport == 'football'
        ? 'footballFields'
        : sport == 'basketball'
            ? 'basketballCourts'
            : 'padelHalls';

    final venues = await _firestore.collection('venues').where(fieldName, isGreaterThan: 0).get();

    if (venues.docs.isEmpty) return null;

    final avgLat = players.map((e) => e.location.latitude).reduce((a, b) => a + b) / players.length;
    final avgLng = players.map((e) => e.location.longitude).reduce((a, b) => a + b) / players.length;

    venues.docs.sort((a, b) {
      final aDist = _distance(a['location'], avgLat, avgLng);
      final bDist = _distance(b['location'], avgLat, avgLng);
      return aDist.compareTo(bDist);
    });

    final closest = venues.docs.first;
    return {
      'id': closest.id,
      'name': closest['name'],
    };
  }

  double _distance(GeoPoint point, double lat, double lng) {
    return (point.latitude - lat).abs() + (point.longitude - lng).abs();
  }

  MatchModel _buildMatchModel(
    String id,
    List<QueueEntryModel> team1,
    List<QueueEntryModel> team2,
    Map<String, dynamic> venue,
    String time,
  ) {
    final players = [...team1, ...team2];
    return MatchModel(
      id: id,
      time: DateTime.now(),
      location: venue['name'] ?? '',
      venueId: venue['id'],
      sport: 'padel',
      mode: '2v2',
      team1: team1.map((e) => e.userId).toList(),
      team2: team2.map((e) => e.userId).toList(),
      statusMap: {
        for (var e in players) e.userId: 'pending',
      },
      createdAt: DateTime.now(),
    );
  }

  Map<String?, List<QueueEntryModel>> _groupByParty(List<QueueEntryModel> group) {
    final Map<String?, List<QueueEntryModel>> partyMap = {};
    for (final entry in group) {
      partyMap.putIfAbsent(entry.partyId, () => []).add(entry);
    }
    return partyMap;
  }
}
