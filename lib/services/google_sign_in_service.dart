import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<UserCredential?> signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
    final GoogleSignInAccount? gUser = await googleSignIn.signIn();

    if (gUser == null) return null;

    final GoogleSignInAuthentication gAuth = await gUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    final langCode = PlatformDispatcher.instance.locale.languageCode;
    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (!userDoc.exists) {
      final fullName = user.displayName ?? '';
      final parts = fullName.trim().split(' ');
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      await userRef.set({
        'email': user.email,
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'socialScore': 100.0,
        'birthDate': null,
        'phone': null,
        'language': langCode,
        'fcmToken': fcmToken,
        'friends': [],
        'friendRequests': [],
        'sentRequests': [],
        'blockedUsers': [],
        'selectedSports': [],
        'positions': [],
        'isSetupComplete': false,
      });
    } else {
      await userRef.set({
        'language': langCode,
        'fcmToken': fcmToken,
      }, SetOptions(merge: true));
    }

    return userCredential;
  } catch (e) {
    print("Google Sign-In Error: $e");
    return null;
  }
}
