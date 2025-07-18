import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PartyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  CollectionReference get _partiesCollection => _firestore.collection('parties');

  Future<void> createParty({
    required String sportId,
    required List<String> inviteUserIds,
  }) async {
    final partyDoc = _partiesCollection.doc(sportId);
    await partyDoc.set({
      'hostId': uid,
      'members': [uid],
      'invites': inviteUserIds,
      'sportId': sportId,
    });
  }

  Future<void> acceptInvite(String sportId) async {
    final docRef = _partiesCollection.doc(sportId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final members = List<String>.from(data['members'] ?? []);
      final invites = List<String>.from(data['invites'] ?? []);

      if (!members.contains(uid)) members.add(uid);
      invites.remove(uid);

      transaction.update(docRef, {
        'members': members,
        'invites': invites,
      });
    });
  }

  Future<void> declineInvite(String sportId) async {
    final docRef = _partiesCollection.doc(sportId);
    await docRef.update({
      'invites': FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> leaveParty(String sportId) async {
    final docRef = _partiesCollection.doc(sportId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final members = List<String>.from(data['members'] ?? []);

      members.remove(uid);

      if (members.isEmpty) {
        transaction.delete(docRef);
      } else {
        transaction.update(docRef, {'members': members});
      }
    });
  }

  Future<void> disbandParty(String sportId) async {
    final docRef = _partiesCollection.doc(sportId);
    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot['hostId'] == uid) {
      await docRef.delete();
    }
  }

Future<void> inviteMoreUsers(String sportId, List<String> userIds) async {
  final docRef = FirebaseFirestore.instance.collection('parties').doc(sportId);
  final doc = await docRef.get();

  if (!doc.exists) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    await docRef.set({
      'hostId': currentUserId,
      'members': [currentUserId],
      'invites': userIds,
    });
  } else {
    final data = doc.data();
    if (data == null) return;

    final List<String> currentInvites = List<String>.from(data['invites'] ?? []);
    final newInvites = {...currentInvites, ...userIds}.toList();

    await docRef.update({
      'invites': newInvites,
    });
  }
}

Stream<DocumentSnapshot> getPartyStream(String sportId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    return _partiesCollection.doc(sportId).snapshots().where((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return false;

      final members = List<String>.from(data['members'] ?? []);
      final invites = List<String>.from(data['invites'] ?? []);

      return members.contains(uid) || invites.contains(uid);
    });
  }
}