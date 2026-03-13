const express = require('express');
const router = express.Router();
const { auth, db } = require('../services/firebase');
const authService = require('../services/authService');
const { sendPasswordResetEmail, sendOTPEmail } = require('../services/emailService');
const { generateOTP, saveOTP, verifyOTP } = require('../services/otpService');

// Request a Firebase password reset link and send via backend email service
router.post('/forgot-password', async (req, res) => {
    const { email } = req.body;
    if (!email) {
        return res.status(400).json({ error: 'Email is required' });
    }

    // Ensure email is valid before hitting Firebase
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({ error: 'Invalid email format' });
    }

    try {
        // Step 1: Verify if user exists (prevents generation of orphan links)
        try {
            await auth.getUserByEmail(email);
        } catch (error) {
            if (error.code === 'auth/user-not-found') {
                // Return success even if user not found to prevent email enumeration
                return res.json({ message: 'If an account exists with this email, a reset link has been sent.' });
            }
            throw error;
        }

        // Generate a password reset link using Firebase Admin SDK
        const link = await auth.generatePasswordResetLink(email);
        
        // Send the email using our custom backend email service
        await sendPasswordResetEmail(email, link);
        
        res.json({ message: 'If an account exists with this email, a reset link has been sent.' });
    } catch (error) {
        console.error('Error in forgot-password flow:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Request an OTP for password reset
router.post('/request-otp', async (req, res) => {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    // Basic email validation regex
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({ error: 'Invalid email format' });
    }

    console.log(`[OTP Request] Attempting for: ${email}`);
    try {
        try {
            await auth.getUserByEmail(email);
        } catch (error) {
            if (error.code === 'auth/user-not-found') {
                console.log(`[OTP Request] User not found: ${email} - sending generic success.`);
                // We still return success to prevent email enumeration, 
                // but we don't actually send an OTP to a non-existent user.
                return res.json({ message: 'If an account exists, an OTP has been sent.' });
            }
            throw error; // Rethrow other auth errors (like invalid-email if regex missed it)
        }

        const otp = generateOTP();
        console.log(`[OTP Request] Generated OTP for ${email}`);
        
        // Step 2: Store OTP in Firestore with 10-minute expiration
        await saveOTP(email, otp);
        console.log(`[OTP Request] Saved OTP to Firestore for ${email}`);

        // Step 3: Send HTML email via Nodemailer
        try {
            await sendOTPEmail(email, otp);
            console.log(`[OTP Request] Email sent successfully to ${email}`);
            res.json({ message: 'OTP sent successfully to your email.' });
        } catch (emailError) {
            console.error(`[OTP Request] Email Sending Failed for ${email}:`, emailError.message);
            res.status(500).json({ 
                error: 'Failed to send OTP email', 
                details: emailError.message 
            });
        }
    } catch (error) {
        console.error(`[OTP Request] CRITICAL FAILURE for ${email}:`, error);
        const statusCode = error.code && error.code.startsWith('auth/') ? 400 : 500;
        res.status(statusCode).json({ 
            error: 'Failed to process OTP request', 
            details: error.message,
            code: error.code 
        });
    }
});

// Verify OTP
router.post('/verify-otp', async (req, res) => {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ error: 'Email and OTP are required' });

    try {
        await verifyOTP(email, otp);
        res.json({ message: 'OTP verified successfully.', success: true });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Reset password using OTP
router.post('/reset-password-otp', async (req, res) => {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) return res.status(400).json({ error: 'Data missing' });

    if (newPassword.length < 6) {
        return res.status(400).json({ error: 'Password must be at least 6 characters.' });
    }

    try {
        const user = await auth.getUserByEmail(email);
        await auth.updateUser(user.uid, { password: newPassword });
        res.json({ message: 'Password updated successfully!' });
    } catch (error) {
        res.status(500).json({ error: 'Update failed' });
    }
});

// Update profile — persists displayName to Firestore AND Firebase Auth

const authenticateToken = async (req, res, next) => {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    try {
        req.user = await authService.verifyToken(token);
        next();
    } catch (err) {
        return res.status(401).json({ error: err.message });
    }
};

router.post('/update-profile', authenticateToken, async (req, res) => {
    const { displayName } = req.body;
    const uid = req.user.uid;

    if (!displayName || displayName.trim().length < 1) {
        return res.status(400).json({ error: 'Display name is required.' });
    }
    if (displayName.trim().length > 50) {
        return res.status(400).json({ error: 'Display name must be under 50 characters.' });
    }

    try {
        // 1. Update Firebase Auth user record
        await auth.updateUser(uid, { displayName: displayName.trim() });

        // 2. Persist in Firestore users collection
        await db.collection('users').doc(uid).set({
            uid,
            displayName: displayName.trim(),
            email: req.user.email,
            updatedAt: new Date().toISOString(),
        }, { merge: true });

        res.json({ message: 'Profile updated successfully.', displayName: displayName.trim() });
    } catch (error) {
        console.error('Profile update error:', error);
        res.status(500).json({ error: 'Failed to update profile.' });
    }
});

module.exports = router;

