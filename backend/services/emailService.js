const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

const sendReminderEmail = async (userEmail, event) => {
    const mailOptions = {
        from: process.env.EMAIL_USER,
        to: userEmail,
        subject: `Reminder: ${event.subject}`,
        text: `Your event "${event.subject}" is starting soon at ${event.startTime}.\nLocation: ${event.location || 'N/A'}`,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`Reminder email sent to ${userEmail}`);
    } catch (error) {
        console.error('Error sending email:', error);
    }
};

const sendPasswordResetEmail = async (userEmail, resetLink) => {
    const mailOptions = {
        from: process.env.EMAIL_USER,
        to: userEmail,
        subject: 'Password Reset Request',
        html: `
            <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
                <h2 style="color: #3f51b5;">Password Reset</h2>
                <p>You requested a password reset for your Vibrant Scheduler account.</p>
                <p>Click the button below to reset your password. This link will expire shortly.</p>
                <a href="${resetLink}" style="display: inline-block; padding: 10px 20px; background-color: #3f51b5; color: white; text-decoration: none; border-radius: 5px;">Reset Password</a>
                <p>If you did not request this, please ignore this email.</p>
                <hr>
                <p style="font-size: 12px; color: #777;">Vibrant Scheduler Team</p>
            </div>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`Password reset email sent to ${userEmail}`);
    } catch (error) {
        console.error('Error sending reset email:', error);
        throw error;
    }
};

const sendOTPEmail = async (userEmail, otp) => {
    const mailOptions = {
        from: process.env.EMAIL_USER,
        to: userEmail,
        subject: 'Your Password Reset OTP Code',
        html: `
            <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #3f51b5; border-radius: 10px; text-align: center;">
                <h2 style="color: #3f51b5;">Authentication</h2>
                <p>Use the following 6-digit OTP to complete your password reset. This code is valid for 10 minutes:</p>
                <div style="font-size: 32px; font-weight: bold; padding: 10px; background-color: #f4f4f4; border-radius: 5px; color: #3f51b5; letter-spacing: 5px;">
                    ${otp}
                </div>
                <p>If you did not request this, please ignore this email.</p>
                <hr>
                <p style="font-size: 12px; color: #777;">Vibrant Scheduler Team</p>
            </div>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`OTP email sent to ${userEmail}`);
    } catch (error) {
        console.error('Error sending OTP email:', error);
        throw error;
    }
};

module.exports = { sendReminderEmail, sendPasswordResetEmail, sendOTPEmail };
