const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

exports.onCellCaptured = functions.firestore.document('territory/{cellId}').onWrite(async (change, context) => {
  const newData = change.after.data();
  const prevData = change.before.data();
  if (!change.after.exists) return null;
  const ownerId = newData?.ownerId;
  if (!ownerId) return null;
  if (!change.before.exists || prevData?.ownerId !== ownerId) {
    const xpGain = 10;
    const userRef = db.collection('users').doc(ownerId);
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;
      const currentXp = userDoc.data()?.xp || 0;
      const currentCells = userDoc.data()?.totalCells || 0;
      if (change.before.exists && prevData?.ownerId && prevData?.ownerId !== ownerId) {
        const prevOwnerRef = db.collection('users').doc(prevData.ownerId);
        const prevOwnerDoc = await transaction.get(prevOwnerRef);
        if (prevOwnerDoc.exists) {
          transaction.update(prevOwnerRef, { totalCells: Math.max(0, (prevOwnerDoc.data()?.totalCells || 1) - 1) });
        }
      }
      transaction.update(userRef, { xp: currentXp + xpGain, totalCells: currentCells + 1 });
    });
  }
  return null;
});

exports.processRunCompletion = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  const { userId, capturedCells, distanceMeters, durationSeconds } = data;
  if (userId !== context.auth.uid) throw new functions.https.HttpsError('permission-denied', 'User mismatch');
  const batch = db.batch();
  const xpPerCell = 10;
  const distanceBonus = Math.floor((distanceMeters || 0) / 1000) * 5;
  const totalXp = (capturedCells?.length || 0) * xpPerCell + distanceBonus;
  for (const cellId of (capturedCells || [])) {
    batch.set(db.collection('territory').doc(cellId), {
      ownerId: userId, capturedAt: admin.firestore.FieldValue.serverTimestamp(), isContested: false,
    }, { merge: true });
  }
  batch.update(db.collection('users').doc(userId), {
    xp: admin.firestore.FieldValue.increment(totalXp),
    totalCells: admin.firestore.FieldValue.increment(capturedCells?.length || 0),
    totalDistanceKm: admin.firestore.FieldValue.increment((distanceMeters || 0) / 1000),
  });
  batch.set(db.collection('runs').doc(), {
    userId, capturedCells: capturedCells?.length || 0, distanceKm: (distanceMeters || 0) / 1000,
    durationSec: durationSeconds || 0, xpEarned: totalXp, date: admin.firestore.FieldValue.serverTimestamp(),
  });
  await batch.commit();
  return { success: true, xpEarned: totalXp };
});

exports.resetContestedTerritories = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const snapshot = await db.collection('territory').where('isContested', '==', true).get();
  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.update(doc.ref, { isContested: false }));
  if (snapshot.size > 0) await batch.commit();
  console.log(`Reset ${snapshot.size} contested territories`);
  return null;
});

exports.cleanupOldRuns = functions.pubsub.schedule('every 7 days').onRun(async (context) => {
  const cutoff = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000));
  const snapshot = await db.collection('runs').where('date', '<', cutoff).get();
  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  if (snapshot.size > 0) await batch.commit();
  console.log(`Cleaned up ${snapshot.size} old runs`);
  return null;
});