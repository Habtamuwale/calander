const cron = require('node-cron');
const { db, auth } = require('./firebase');
const { sendReminderEmail } = require('./emailService');

const startReminderScheduler = () => {
    // Run every minute
    cron.schedule('* * * * *', async () => {
        console.log('Running reminder check...');
        const now = new Date();
        const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);

        try {
            // Find events with hasReminder: true
            const snapshot = await db.collection('events')
                .where('hasReminder', '==', true)
                .get();

            const events = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            for (const event of events) {
                const startTime = new Date(event.StartTime);
                const reminderTime = new Date(startTime.getTime() - (event.reminderMinutesBefore || 15) * 60 * 1000);

                // Check if it's time to send the reminder
                // For simplicity: if current time is within 1 minute of reminder time and not sent yet
                if (now >= reminderTime && now < startTime && !event.reminderSent) {
                    try {
                        const user = await auth.getUser(event.userId);
                        if (user && user.email) {
                            await sendReminderEmail(user.email, event);

                            // Mark as sent to prevent duplicate emails
                            await db.collection('events').doc(event.id).update({ reminderSent: true });
                        }
                    } catch (err) {
                        console.error(`Error processing reminder for event ${event.id}:`, err);
                    }
                }
            }
        } catch (error) {
            console.error('Error fetching events for reminders:', error);
        }
    });
};

module.exports = { startReminderScheduler };
