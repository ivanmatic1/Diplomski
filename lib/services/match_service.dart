import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match_model.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MatchModel>> fetchMatches({
    String sport = 'all',
    bool recentFirst = true,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      print('Current userId: $userId');

      if (userId == null) {
        print('No logged-in user found.');
        return [];
      }

      Query query = _firestore
          .collection('matches')
          .where('participants', arrayContains: userId);

      if (sport != 'all') {
        query = query.where('sport', isEqualTo: sport);
      }

      query = query.orderBy('time', descending: recentFirst);

      final snapshot = await query.get();


      return snapshot.docs.map((doc) {
        return MatchModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, String>> getUserNames(List<String> userIds) async {
    final usersCollection = _firestore.collection('users');
    final names = <String, String>{};

    final futures = userIds.map((id) async {
      final doc = await usersCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        final fullName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        names[id] = fullName.isNotEmpty ? fullName : id;
      } else {
        names[id] = id;
      }
    });

    await Future.wait(futures);
    return names;
  }
}
