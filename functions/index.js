const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.getUserByDisplayName = functions.https.onCall(async (data, context) => {
  const displayName = data.displayName;

  if (!displayName) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with " +
      "one arguments 'displayName' containing the display name to look up.",
    );
  }

  try {
    const usersRef = admin.firestore().collection("users");
    const snapshot = await usersRef.get();

    let userEmail = null;

    snapshot.forEach((doc) => {
      const user = doc.data();
      if (user.displayName.toLowerCase() === displayName.toLowerCase()) {
        userEmail = user.email;
      }
    });

    if (userEmail) {
      return {email: userEmail};
    } else {
      throw new functions.https.HttpsError(
          "not-found",
          `User with display name ${displayName} not found.`,
      );
    }
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message, error);
  }
});
