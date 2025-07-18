import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:terminko/models/stat_model.dart';

final _storage = FirebaseStorage.instance;
final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

Future<String?> getCurrentUserId() async {
  final user = _auth.currentUser;
  return user?.uid;
}

Future<Map<String, dynamic>> getProfileData() async {
  final uid = await getCurrentUserId();
  if (uid == null) return {};

  final doc = await _firestore.collection('users').doc(uid).get();
  return doc.data() ?? {};
}

Future<StatModel> fetchGlobalStatsModel() async {
  final uid = await getCurrentUserId();
  if (uid == null) return StatModel.empty();

  final doc = await _firestore
      .collection('users')
      .doc(uid)
      .collection('stats')
      .doc('global')
      .get();

  return doc.exists ? StatModel.fromMap(doc.data()!) : StatModel.empty();
}

Future<List<String>> fetchSelectedSports() async {
  final uid = await getCurrentUserId();
  if (uid == null) return [];

  final doc = await _firestore.collection('users').doc(uid).get();
  final data = doc.data();
  if (data == null || !data.containsKey('selectedSports')) return [];

  final List<dynamic> rawList = data['selectedSports'];
  return rawList.whereType<String>().toList();
}

Future<Map<String, StatModel>> fetchStatsBySportModel(List<String> sportIds) async {
  final uid = await getCurrentUserId();
  if (uid == null) return {};

  final Map<String, StatModel> stats = {};

  for (final sportId in sportIds) {
    final doc = await _firestore.collection('users').doc(uid).collection('stats').doc(sportId).get();
    if (doc.exists) {
      stats[sportId] = StatModel.fromMap(doc.data()!);
    }
  }

  return stats;
}

Future<void> updateUserProfile({
  String? firstName,
  String? lastName,
  String? email,
  String? phone,
  DateTime? birthDate,
  String? imageUrl,
}) async {
  final uid = await getCurrentUserId();
  if (uid == null) return;

  final Map<String, dynamic> updates = {};
  if (firstName != null) updates['firstName'] = firstName;
  if (lastName != null) updates['lastName'] = lastName;
  if (email != null) updates['email'] = email;
  if (phone != null) updates['phone'] = phone;
  if (birthDate != null) updates['birthDate'] = Timestamp.fromDate(birthDate);
  if (imageUrl != null) updates['imageUrl'] = imageUrl;

  await _firestore.collection('users').doc(uid).update(updates);
}

Future<String?> uploadProfileImage(File imageFile) async {
  final uid = await getCurrentUserId();
  if (uid == null) return null;

  final ref = _storage.ref().child('profile_images/$uid.jpg');
  await ref.putFile(imageFile);
  return await ref.getDownloadURL();
}
