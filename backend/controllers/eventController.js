const { db, admin } = require('../services/firebase');

// --- Shared Validation ---
const validateEventData = (data) => {
    const errors = [];

    if (!data.Subject && !data.subject) {
        errors.push('Event title (Subject) is required.');
    } else {
        const title = (data.Subject || data.subject || '').trim();
        if (title.length < 2) errors.push('Title must be at least 2 characters.');
        if (title.length > 100) errors.push('Title must be under 100 characters.');
    }

    const startRaw = data.StartTime || data.startTime;
    const endRaw = data.EndTime || data.endTime;

    if (!startRaw) {
        errors.push('Start time is required.');
    }
    if (!endRaw) {
        errors.push('End time is required.');
    }

    if (startRaw && endRaw) {
        const start = new Date(startRaw);
        const end = new Date(endRaw);
        if (isNaN(start.getTime())) errors.push('Start time is not a valid date.');
        if (isNaN(end.getTime())) errors.push('End time is not a valid date.');
        if (!isNaN(start.getTime()) && !isNaN(end.getTime())) {
            if (end <= start) errors.push('End time must be after start time.');
            const diffMins = (end - start) / 60000;
            if (diffMins < 5) errors.push('Event must be at least 5 minutes long.');
        }
    }

    return errors;
};

exports.createEvent = async (req, res) => {
    const errors = validateEventData(req.body);
    if (errors.length > 0) {
        return res.status(400).json({ error: errors[0], errors });
    }

    try {
        const eventData = req.body;
        eventData.userId = req.user.uid;
        eventData.createdAt = admin.firestore.FieldValue.serverTimestamp();
        const docRef = await db.collection('events').add(eventData);
        res.status(201).json({ ...eventData, id: docRef.id });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

exports.getEvents = async (req, res) => {
    try {
        const snapshot = await db.collection('events').where('userId', '==', req.user.uid).get();
        const events = snapshot.docs.map(doc => ({ ...doc.data(), id: doc.id }));
        res.json(events);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

exports.updateEvent = async (req, res) => {
    const errors = validateEventData(req.body);
    if (errors.length > 0) {
        return res.status(400).json({ error: errors[0], errors });
    }

    try {
        const id = req.params.id;

        // Ownership check — ensure user can only update their own event
        const doc = await db.collection('events').doc(id).get();
        if (!doc.exists) return res.status(404).json({ error: 'Event not found.' });
        if (doc.data().userId !== req.user.uid) return res.status(403).json({ error: 'Not allowed to update this event.' });

        const updateData = req.body;
        delete updateData.userId; // Never allow overwriting userId
        updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
        await db.collection('events').doc(id).update(updateData);
        res.json({ ...updateData, id });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

exports.deleteEvent = async (req, res) => {
    try {
        // Ownership check
        const doc = await db.collection('events').doc(req.params.id).get();
        if (!doc.exists) return res.status(404).json({ error: 'Event not found.' });
        if (doc.data().userId !== req.user.uid) return res.status(403).json({ error: 'Not allowed to delete this event.' });

        await db.collection('events').doc(req.params.id).delete();
        res.json({ message: 'Event successfully deleted.' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};
