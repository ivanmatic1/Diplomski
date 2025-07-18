const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {https} = require("firebase-functions/v2");
const {setGlobalOptions} = require("firebase-functions/v2/options");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

setGlobalOptions({maxInstances: 10});

exports.sendFriendRequestNotification = onDocumentCreated(
    "users/{userId}/incomingRequests/{requestId}",
    async (event) => {
      const data = event.data.data();
      const fromUserId = data.from;
      const toUserId = event.params.userId;

      const toUserDoc = await db.collection("users").doc(toUserId).get();
      const fromUserDoc = await db.collection("users").doc(fromUserId).get();
      if (!toUserDoc.exists || !fromUserDoc.exists) return;

      const toUserData = toUserDoc.data();
      const fromUserData = fromUserDoc.data();

      const lang = toUserData.language || "en";
      const senderName = `${fromUserData.firstname} ${fromUserData.lastname}`;

      const translations = {
        en: {
          title: "New friend request",
          body: `${senderName} sent you a friend request.`,
        },
        hr: {
          title: "Zahtjev za prijateljstvo",
          body: `${senderName} ti je poslao zahtjev za prijateljstvo.`,
        },
      };

      const message = translations[lang] || translations["en"];
      const fcmToken = toUserData.fcmToken;
      if (!fcmToken) return;

      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: message.title,
          body: message.body,
        },
        data: {
          type: "friend_request",
          senderId: fromUserId,
        },
      });
    },
);

exports.sendFriendAcceptNotification = onDocumentCreated(
    "users/{userId}/friends/{friendId}",
    async (event) => {
      const userId = event.params.userId;
      const friendId = event.params.friendId;

      const changeType = event.data;
      if (!changeType) return;

      const userDoc = await db.collection("users").doc(userId).get();
      const friendDoc = await db.collection("users").doc(friendId).get();
      if (!userDoc.exists || !friendDoc.exists) return;

      const userData = userDoc.data();
      const friendData = friendDoc.data();

      const lang = friendData.language || "en";
      const accepterName = `${userData.firstname} ${userData.lastname}`;

      const translations = {
        en: {
          title: "Friend request accepted",
          body: `${accepterName} accepted your friend request.`,
        },
        hr: {
          title: "Zahtjev prihvaćen",
          body: `${accepterName} je prihvatio tvoj zahtjev.`,
        },
      };

      const message = translations[lang] || translations["en"];
      const fcmToken = friendData.fcmToken;
      if (!fcmToken) return;

      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: message.title,
          body: message.body,
        },
        data: {
          type: "friend_accepted",
          accepterId: userId,
        },
      });
    },
);

exports.sendMatchFoundNotification = onDocumentCreated(
    "matchConfirmations/{matchId}/pending/{userId}",
    async (event) => {
      const {matchId, userId} = event.params;

      const matchDoc = await db.collection("matches").doc(matchId).get();
      const userDoc = await db.collection("users").doc(userId).get();

      if (!matchDoc.exists || !userDoc.exists) return;

      const userData = userDoc.data();
      const lang = userData.language || "en";

      const translations = {
        en: {
          title: "Match found!",
          body: "Please confirm your participation.",
        },
        hr: {
          title: "Pronađen meč!",
          body: "Potvrdi da želiš igrati.",
        },
      };

      const message = translations[lang] || translations["en"];
      const fcmToken = userData.fcmToken;
      if (!fcmToken) return;

      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: message.title,
          body: message.body,
        },
        data: {
          type: "match_found",
          matchId: matchId,
        },
      });
    },
);

exports.getFriendsWithDetails = https.onCall(async (request, context) => {
  if (!context.auth) {
    throw new https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const uid = context.auth.uid;

  try {
    const friendsSnapshot=
    await db.collection("users").doc(uid).collection("friends").get();
    if (friendsSnapshot.empty) return [];

    const friendIds = friendsSnapshot.docs.map((doc) => doc.id);

    const friendsDataPromises=
    friendIds.map((id) => db.collection("users").doc(id).get());
    const friendsDocs = await Promise.all(friendsDataPromises);

    const friends = friendsDocs
        .filter((doc) => doc.exists)
        .map((doc) => {
          const data = doc.data();
          return {
            id: doc.id,
            firstName: data.firstName || data.firstname || "",
            lastName: data.lastName || data.lastname || "",
            avatarUrl: data.avatarUrl || "",
            email: data.email || "",
          };
        });

    return friends;
  } catch (error) {
    console.error("Error fetching friends:", error);
    throw new https.HttpsError("internal", "Failed to fetch friends");
  }
});
