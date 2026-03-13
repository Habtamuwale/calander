const express = require('express');
const router = express.Router();
const eventController = require('../controllers/eventController');
const authService = require('../services/authService');

// Auth Middleware
const authenticate = async (req, res, next) => {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) return res.status(401).json({ error: 'Unauthorized: No token provided' });
    try {
        const decodedVal = await authService.verifyToken(token);
        req.user = decodedVal;
        next();
    } catch (err) {
        return res.status(401).json({ error: err.message });
    }
};

router.use(authenticate);

router.post('/', eventController.createEvent);
router.get('/', eventController.getEvents);
router.put('/:id', eventController.updateEvent);
router.delete('/:id', eventController.deleteEvent);

module.exports = router;
