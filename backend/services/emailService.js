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

module.exports = { sendReminderEmail };
