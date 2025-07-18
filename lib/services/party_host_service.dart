import 'package:cloud_firestore/cloud_firestore.dart';

class PartyHostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getPartyHostForSport(String userId, String sportId) async {
    final query = await _firestore
        .collection('parties')
        .where('sportId', isEqualTo: sportId)
        .where('members', arrayContains: userId)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    return doc.data()['hostId'] as String?;
  }
}
