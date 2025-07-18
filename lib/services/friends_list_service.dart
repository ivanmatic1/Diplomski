import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:terminko/models/friend_model.dart';
import 'package:terminko/models/user_model.dart';

final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

Future<String?> _getUid() async {
  final user = _auth.currentUser;
  return user?.uid;
}

Future<void> sendFriendRequest(String targetUserId) async {
  final uid = await _getUid();
  if (uid == null || uid == targetUserId) return;

  final requestRef = _firestore
      .collection('users')
      .doc(targetUserId)
      .collection('incomingRequests')
      .doc(uid);

  await requestRef.set({
    'from': uid,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

Future<void> acceptFriendRequest(String fromUserId) async {
  final uid = await _getUid();
  if (uid == null) return;

  final batch = _firestore.batch();

  final userRef = _firestore.collection('users').doc(uid);
  final fromRef = _firestore.collection('users').doc(fromUserId);

  batch.set(userRef.collection('friends').doc(fromUserId), {
    'uid': fromUserId,
    'timestamp': FieldValue.serverTimestamp(),
  });

  batch.set(fromRef.collection('friends').doc(uid), {
    'uid': uid,
    'timestamp': FieldValue.serverTimestamp(),
  });

  final requestRef = userRef.collection('incomingRequests').doc(fromUserId);
  batch.delete(requestRef);

  await batch.commit();
}

Future<void> declineFriendRequest(String fromUserId) async {
  final uid = await _getUid();
  if (uid == null) return;

  await _firestore
      .collection('users')
      .doc(uid)
      .collection('incomingRequests')
      .doc(fromUserId)
      .delete();
}

Future<void> blockUser(String targetUserId) async {
  final uid = await _getUid();
  if (uid == null || uid == targetUserId) return;

  await _firestore
      .collection('users')
      .doc(uid)
      .collection('blocked')
      .doc(targetUserId)
      .set({'timestamp': FieldValue.serverTimestamp()});

  await removeFriend(targetUserId);
}

Future<void> unblockUser(String targetUserId) async {
  final uid = await _getUid();
  if (uid == null) return;

  await _firestore
      .collection('users')
      .doc(uid)
      .collection('blocked')
      .doc(targetUserId)
      .delete();
}

Stream<List<FriendModel>> getFriendsStream() async* {
  final uid = await _getUid();
  if (uid == null) yield [];

  yield* _firestore
      .collection('users')
      .doc(uid)
      .collection('friends')
      .snapshots()
      .asyncMap((snapshot) async {
    final friendIds = snapshot.docs.map((doc) => doc.id).toList();
    if (friendIds.isEmpty) return [];

    final friendsSnapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .get();

    return friendsSnapshot.docs.map((doc) {
      final userModel = UserModel.fromMap(doc.id, doc.data());
      return FriendModel(id: doc.id, user: userModel);
    }).toList();
  });
}

Stream<List<FriendModel>> getIncomingFriendRequestsStream() async* {
  final uid = await _getUid();
  if (uid == null) yield [];

  yield* _firestore
      .collection('users')
      .doc(uid)
      .collection('incomingRequests')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    return Future.wait(snapshot.docs.map((doc) async {
      final fromId = doc.id;
      final userDoc = await getUserDataById(fromId);
      if (userDoc == null) return null;

      final userModel = UserModel.fromMap(fromId, userDoc);
      return FriendModel(id: fromId, user: userModel);
    })).then((list) => list.whereType<FriendModel>().toList());
  });
}

Stream<List<FriendModel>> getBlockedUsersStream() async* {
  final uid = await _getUid();
  if (uid == null) yield [];

  yield* _firestore
      .collection('users')
      .doc(uid)
      .collection('blocked')
      .snapshots()
      .asyncMap((snapshot) async {
    final blockedIds = snapshot.docs.map((doc) => doc.id).toList();

    final users = <FriendModel>[];
    for (final id in blockedIds) {
      final userDoc = await getUserDataById(id);
      if (userDoc != null) {
        final userModel = UserModel.fromMap(id, userDoc);
        users.add(FriendModel(id: id, user: userModel));
      }
    }

    return users;
  });
}

Future<void> removeFriend(String targetUserId) async {
  final uid = await _getUid();
  if (uid == null || uid == targetUserId) return;

  final batch = _firestore.batch();

  final userRef = _firestore.collection('users').doc(uid);
  final targetRef = _firestore.collection('users').doc(targetUserId);

  batch.delete(userRef.collection('friends').doc(targetUserId));
  batch.delete(targetRef.collection('friends').doc(uid));

  await batch.commit();
}

Future<Map<String, dynamic>?> getUserDataById(String uid) async {
  final doc = await _firestore.collection('users').doc(uid).get();
  if (!doc.exists) return null;
  return doc.data();
}

Future<void> sendLobbyInvite(String targetUserId) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null || uid == targetUserId) return;

  final existing = await _firestore
      .collection('lobbyInvites')
      .where('from', isEqualTo: uid)
      .where('to', isEqualTo: targetUserId)
      .where('status', isEqualTo: 'pending')
      .get();

  if (existing.docs.isNotEmpty) return;

  await _firestore.collection('lobbyInvites').add({
    'from': uid,
    'to': targetUserId,
    'timestamp': FieldValue.serverTimestamp(),
    'status': 'pending',
  });
}

Future<List<UserModel>> getFriends() async {
  final uid = await _getUid();
  if (uid == null) return [];

  final snapshot = await _firestore
      .collection('users')
      .doc(uid)
      .collection('friends')
      .get();

  final friendIds = snapshot.docs.map((doc) => doc.id).toList();
  if (friendIds.isEmpty) return [];

  final friendsSnapshot = await _firestore
      .collection('users')
      .where(FieldPath.documentId, whereIn: friendIds)
      .get();

  return friendsSnapshot.docs.map((doc) {
    return UserModel.fromMap(doc.id, doc.data());
  }).toList();
}
