import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:terminko/models/sport_details_model.dart';
import 'package:terminko/services/firestore_service.dart';

class MainPageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  Future<String?> getActiveSport() async {
    final uid = await getCurrentUserId();
    if (uid == null) return null;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['activeSport'] as String?;
  }

  Future<List<String>> getSelectedSports() async {
    final uid = await getCurrentUserId();
    if (uid == null) return [];

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final list = userDoc.data()?['selectedSports'];
    return list is List ? List<String>.from(list) : [];
  }

  Future<void> updateActiveSport(String sportId) async {
    final uid = await getCurrentUserId();
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'activeSport': sportId,
    });
  }

  Future<SportDetailsModel?> getSportDetails(String sportId) async {
    return await getSportData(sportId);
  }

  Future<List<int>> getCounts(List<String> sports) async {
    return List.filled(sports.length, 0);
  }
}
