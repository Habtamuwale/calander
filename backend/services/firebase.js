const admin = require('firebase-admin');

try {
    const serviceAccount = require('../serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
} catch (e) {
    console.warn("Could NOT find serviceAccountKey.json in backend/ folder. Warning: Firebase Admin may not work correctly without proper credentials.");
    admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

module.exports = { admin, db, auth };
