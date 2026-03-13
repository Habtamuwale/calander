const { db } = require('./firebase');

/**
 * Generates a 6-digit OTP
 */
const generateOTP = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Saves OTP to Firestore with an expiration time (10 minutes)
 */
const saveOTP = async (email, otp) => {
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10);

    await db.collection('otps').doc(email).set({
        otp,
        expiresAt: expiresAt.toISOString(),
        createdAt: new Date().toISOString()
    });
};

/**
 * Verifies the OTP for a given email
 */
const verifyOTP = async (email, userOtp) => {
    const doc = await db.collection('otps').doc(email).get();
    
    if (!doc.exists) {
        throw new Error('No OTP found for this email');
    }

    const { otp, expiresAt } = doc.data();

    if (new Date() > new Date(expiresAt)) {
        await db.collection('otps').doc(email).delete();
        throw new Error('OTP has expired');
    }

    if (otp !== userOtp) {
        throw new Error('Invalid OTP');
    }

    // OTP is valid, delete it so it can't be reused
    await db.collection('otps').doc(email).delete();
    return true;
};

module.exports = { generateOTP, saveOTP, verifyOTP };
