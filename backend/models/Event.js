class Event {
    constructor(data) {
        this.id = data.id;
        this.userId = data.userId;
        this.subject = data.Subject;
        this.startTime = data.StartTime;
        this.endTime = data.EndTime;
        this.location = data.Location;
        this.recurrenceRule = data.RecurrenceRule;
        this.color = data.Color || '4284571358'; // Default indigo
        this.hasReminder = data.hasReminder || false;
        this.reminderMinutesBefore = data.reminderMinutesBefore || 15;
        this.timezone = data.timezone || 'UTC';
        this.reminderSent = data.reminderSent || false;
        this.createdAt = data.createdAt;
    }

    static fromFirestore(doc) {
        const data = doc.data();
        return new Event({ id: doc.id, ...data });
    }

    toFirestore() {
        return {
            userId: this.userId,
            Subject: this.subject,
            StartTime: this.startTime,
            EndTime: this.endTime,
            Location: this.location,
            RecurrenceRule: this.recurrenceRule,
            Color: this.color,
            hasReminder: this.hasReminder,
            reminderMinutesBefore: this.reminderMinutesBefore,
            timezone: this.timezone,
            reminderSent: this.reminderSent,
            createdAt: this.createdAt
        };
    }
}

module.exports = Event;
