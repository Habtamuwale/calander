const cron = require('node-cron');
const { db, auth } = require('./firebase');
const { sendReminderEmail } = require('./emailService');

const startReminderScheduler = () => {
    // Run every minute
    cron.schedule('* * * * *', async () => {
        console.log('Running reminder check...');
        const now = new Date();

        try {
            // Find events with hasReminder: true
            const snapshot = await db.collection('events')
                .where('hasReminder', '==', true)
                .get();

            const events = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            for (const event of events) {
                // Guard: skip events without a userId
                if (!event.userId) {
                    console.warn(`Event ${event.id} is missing userId, skipping.`);
                    continue;
                }

                // Support both capitalized Firestore keys (StartTime) and lowercase (startTime)
                const rawStartTime = event.StartTime || event.startTime;
                if (!rawStartTime) {
                    console.warn(`Event ${event.id} is missing StartTime, skipping.`);
                    continue;
                }

                const startTime = new Date(rawStartTime);
                const reminderTime = new Date(startTime.getTime() - (event.reminderMinutesBefore || 15) * 60 * 1000);

                // Check if it's time to send the reminder
                if (now >= reminderTime && now < startTime && !event.reminderSent) {
                    try {
                        const user = await auth.getUser(event.userId);
                        if (user && user.email) {
                            const eventTitle = event.Subject || event.subject || 'Your Event';
                            console.log(`Sending reminder to ${user.email} for event: "${eventTitle}"`);
                            await sendReminderEmail(user.email, event);

                            // Mark as sent to prevent duplicate emails
                            await db.collection('events').doc(event.id).update({ reminderSent: true });
                        } else {
                            console.warn(`No email found for userId: ${event.userId}`);
                        }
                    } catch (err) {
                        console.error(`Error processing reminder for event ${event.id}:`, err.message);
                    }
                }
            }
        } catch (error) {
            console.error('Error fetching events for reminders:', error);
        }
    });
};

module.exports = { startReminderScheduler };
