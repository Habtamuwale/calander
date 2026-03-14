const admin = require('firebase-admin');

const fs = require('fs');
const path = require('path');

try {
    const keyPath = path.join(__dirname, '../serviceAccountKey.json');
    if (!fs.existsSync(keyPath)) {
        throw new Error(`serviceAccountKey.json NOT found at ${keyPath}`);
    }
    
    const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
    
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin SDK initialized successfully.');
} catch (e) {
    console.error("CRITICAL: Firebase Admin initialization failed:", e.message);
    // Fallback to default credentials if available, though unlikely to work without proper setup
    admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

module.exports = { admin, db, auth };
