import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:terminko/models/user_model.dart';
import 'package:terminko/models/sport_details_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

Future<void> createUser({
  required String email,
  required String firstName,
  required String lastName,
  required String phoneNumber,
  required String country,
  required String dateOfBirth,
}) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  await _firestore.collection('users').doc(uid).set({
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'createdAt': FieldValue.serverTimestamp(),
    'socialScore': 100,
    'phone': phoneNumber,
    'country': country,
    'birthDate': dateOfBirth,
    'isSetupComplete': false,
    'friends': [],
    'friendRequests': [],
    'sentRequests': [],
    'blockedUsers': [],
  });
}

Future<void> saveSportData(String sportName, SportDetailsModel model) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  await _firestore
      .collection('users')
      .doc(uid)
      .collection('sports')
      .doc(sportName)
      .set(model.toMap(), SetOptions(merge: true));
}

Future<SportDetailsModel?> getSportData(String sportName) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return null;

  final doc = await _firestore
      .collection('users')
      .doc(uid)
      .collection('sports')
      .doc(sportName)
      .get();

  return doc.exists ? SportDetailsModel.fromMap(doc.data()!) : null;
}

Future<List<Map<String, dynamic>>> getAllSportData() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return [];

  final snapshot = await _firestore
      .collection('users')
      .doc(uid)
      .collection('sports')
      .get();

  return snapshot.docs.map((doc) {
    return {
      'sport': doc.id,
      ...doc.data(),
    };
  }).toList();
}

Future<void> updatePreferences({
  required double maxDistanceKm,
}) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  await _firestore.collection('users').doc(uid).update({
    'maxDistanceKm': maxDistanceKm,
  });
}

Future<void> markSetupComplete() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  await _firestore.collection('users').doc(uid).set({
    'isSetupComplete': true,
  }, SetOptions(merge: true));
}

Future<UserModel?> getUserModel() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return null;

  final doc = await _firestore.collection('users').doc(uid).get();
  if (!doc.exists) return null;

  return UserModel.fromMap(doc.id, doc.data()!);
}

Future<UserModel?> getUserById(String uid) async {
  final doc = await _firestore.collection('users').doc(uid).get();
  if (!doc.exists) return null;
  return UserModel.fromMap(doc.id, doc.data()!);
}

Future<void> updateUserModel(UserModel user) async {
  await _firestore.collection('users').doc(user.id).update(user.toMap());
}

Future<bool> isUserSetupComplete(String uid) async {
  final doc = await _firestore.collection('users').doc(uid).get();
  return doc.exists && (doc.data()?['isSetupComplete'] == true);
}

Future<String?> getUserIdByEmail(String email) async {
  final query = await _firestore
      .collection('users')
      .where('email', isEqualTo: email.trim())
      .limit(1)
      .get();

  if (query.docs.isNotEmpty) {
    return query.docs.first.id;
  }
  return null;
}

Future<void> saveLocationForAllSports({
  required double latitude,
  required double longitude,
  required double maxDistanceKm,
}) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  final sportsSnapshot = await _firestore
      .collection('users')
      .doc(uid)
      .collection('sports')
      .get();

  for (final doc in sportsSnapshot.docs) {
    final sportName = doc.id;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('sports')
        .doc(sportName)
        .set({
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'maxDistanceKm': maxDistanceKm,
      }
    }, SetOptions(merge: true));
  }
}

Future<String?> changePassword({
  required BuildContext context,
  required String currentPassword,
  required String newPassword,
}) async {
  final loc = AppLocalizations.of(context)!;

  try {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return loc.user_not_logged_in;
    }

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);

    return null;
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'wrong-password':
        return loc.error_wrong_password;
      case 'weak-password':
        return loc.error_weak_password;
      case 'requires-recent-login':
        return loc.error_requires_recent_login;
      default:
        return '${loc.error_generic}: ${e.message}';
    }
  } catch (e) {
    return '${loc.error_unexpected}: $e';
  }
}
