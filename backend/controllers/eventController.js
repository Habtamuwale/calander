const { db, admin } = require('../services/firebase');

exports.createEvent = async (req, res) => {
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
    try {
        const id = req.params.id;
        const updateData = req.body;
        delete updateData.userId;
        await db.collection('events').doc(id).update(updateData);
        res.json({ ...updateData, id });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

exports.deleteEvent = async (req, res) => {
    try {
        await db.collection('events').doc(req.params.id).delete();
        res.json({ message: 'Event successfully deleted.' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};
