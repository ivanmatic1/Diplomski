import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/queue_entry_model.dart';
import '../services/firestore_service.dart';

class QueueService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> addToQueue(String sportId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    final userModel = await getUserModel();
    if (userModel == null) throw Exception("User model not found");

    final sportData = await getSportData(sportId);
    if (sportData == null) throw Exception("Sport details not found");

    final locationMap = sportData.location;
    if (locationMap == null) throw Exception("Location not set for this sport");

    final GeoPoint location = GeoPoint(
      (locationMap['latitude'] as num).toDouble(),
      (locationMap['longitude'] as num).toDouble(),
    );

    final String position = sportData.positions.isNotEmpty
        ? sportData.positions.first
        : 'flex';

    final String mode = sportData.matchTypes.isNotEmpty
        ? sportData.matchTypes.first
        : 'default';

    final String preferredTime = sportData.preferredTime;
    if (preferredTime.isEmpty) throw Exception("No preferred time selected");

    final entry = QueueEntryModel(
      userId: userId,
      sportId: sportId,
      position: position,
      availableTimes: [preferredTime],
      location: location,
      joinedAt: DateTime.now(),
      mode: mode,
      partyId: null,
    );

    await _firestore
        .collection('queueEntries')
        .doc('$userId-$sportId')
        .set(entry.toMap());
  }
}

Future<void> removeFromQueue(String sportId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  await FirebaseFirestore.instance
      .collection('queueEntries')
      .doc('$userId-$sportId')
      .delete();
}

