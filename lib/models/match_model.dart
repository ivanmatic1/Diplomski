import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final DateTime time;
  final String location;
  final String venueId;
  final String sport;
  final String mode;
  final List<String> team1;
  final List<String> team2;
  final Map<String, String> statusMap;
  final DateTime createdAt;
  final String? winnerTeam;

  MatchModel({
    required this.id,
    required this.time,
    required this.location,
    required this.venueId,
    required this.sport,
    required this.mode,
    required this.team1,
    required this.team2,
    required this.statusMap,
    required this.createdAt,
    this.winnerTeam,
  });

  factory MatchModel.fromMap(String id, Map<String, dynamic> data) {
    return MatchModel(
      id: id,
      time: (data['time'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      venueId: data['venueId'] ?? '',
      sport: data['sport'] ?? '',
      mode: data['mode'] ?? '',
      team1: List<String>.from(data['team1'] ?? []),
      team2: List<String>.from(data['team2'] ?? []),
      statusMap: Map<String, String>.from(data['statusMap'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      winnerTeam: data['winnerTeam'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': Timestamp.fromDate(time),
      'location': location,
      'venueId': venueId,
      'sport': sport,
      'mode': mode,
      'team1': team1,
      'team2': team2,
      'statusMap': statusMap,
      'createdAt': Timestamp.fromDate(createdAt),
      if (winnerTeam != null) 'winnerTeam': winnerTeam,
    };
  }
}
