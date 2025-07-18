import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

Future<void> submitRating(RatingModel rating) async {
  final docId = '${rating.matchId}_${rating.raterId}_${rating.rateeId}';
  await FirebaseFirestore.instance.collection('ratings').doc(docId).set(rating.toMap());
}

Future<bool> hasAlreadyRated(String matchId, String raterId, String rateeId) async {
    final docId = '${matchId}_${raterId}_${rateeId}';
    final doc = await FirebaseFirestore.instance.collection('ratings').doc(docId).get();
    return doc.exists;
}
