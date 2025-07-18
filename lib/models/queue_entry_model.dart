import 'package:cloud_firestore/cloud_firestore.dart';

class QueueEntryModel {
  final String userId;
  final String sportId;
  final String position;
  final List<String> availableTimes;
  final GeoPoint location;
  final String? partyId;
  final DateTime joinedAt;
  final String mode;

  QueueEntryModel({
    required this.userId,
    required this.sportId,
    required this.position,
    required this.availableTimes,
    required this.location,
    required this.joinedAt,
    required this.mode,
    this.partyId,
  });

  factory QueueEntryModel.fromMap(String userId, Map<String, dynamic> data) {
    return QueueEntryModel(
      userId: userId,
      sportId: data['sportId'] ?? '',
      position: data['position'] ?? '',
      availableTimes: List<String>.from(data['availableTimes'] ?? []),
      location: data['location'] ?? GeoPoint(0, 0),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mode: data['mode'] ?? '',
      partyId: data['partyId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sportId': sportId,
      'position': position,
      'availableTimes': availableTimes,
      'location': location,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'mode': mode,
      if (partyId != null) 'partyId': partyId,
    };
  }
}
