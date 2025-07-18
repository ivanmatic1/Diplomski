import 'package:cloud_firestore/cloud_firestore.dart';

class PartyModel {
  final String sportId;
  final String hostId;
  final List<String> members;
  final List<String> invites;
  final DateTime createdAt;
  final GeoPoint? location;

  PartyModel({
    required this.sportId,
    required this.hostId,
    required this.members,
    required this.invites,
    required this.createdAt,
    this.location,
  });

  factory PartyModel.fromMap(String sportId, Map<String, dynamic> data) {
    return PartyModel(
      sportId: sportId,
      hostId: data['hostId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      invites: List<String>.from(data['invites'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'members': members,
      'invites': invites,
      'sportId': sportId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (location != null) 'location': location,
    };
  }
}
