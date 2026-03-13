const express = require('express');
const router = express.Router();
const { auth } = require('../services/firebase');
const { sendPasswordResetEmail, sendOTPEmail } = require('../services/emailService');
const { generateOTP, saveOTP, verifyOTP } = require('../services/otpService');

router.post('/forgot-password', async (req, res) => {
    const { email } = req.body;
    if (!email) {
        return res.status(400).json({ error: 'Email is required' });
    }

    try {
        // Verify user exists in Firebase first to prevent generatePasswordResetLink from throwing
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

    try {
        await auth.getUserByEmail(email);
        const otp = generateOTP();
        await saveOTP(email, otp);
        // Send email in background for faster API response
        sendOTPEmail(email, otp).catch(e => console.error('Background OTP Email Error:', e));
        res.json({ message: 'OTP sent successfully to your email.' });
    } catch (error) {
        if (error.code === 'auth/user-not-found') {
            return res.json({ message: 'If an account exists, an OTP has been sent.' });
        }
        console.error('OTP Request Error:', error);
        res.status(500).json({ error: 'Failed to send OTP' });
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

// Reset password using OTP (Note: In a real app, you'd use a temporary token after verify-otp)
router.post('/reset-password-otp', async (req, res) => {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) return res.status(400).json({ error: 'Data missing' });

    try {
        const user = await auth.getUserByEmail(email);
        await auth.updateUser(user.uid, { password: newPassword });
        res.json({ message: 'Password updated successfully!' });
    } catch (error) {
        res.status(500).json({ error: 'Update failed' });
    }
});

module.exports = router;
