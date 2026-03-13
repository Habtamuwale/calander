const { auth } = require('./firebase');

exports.verifyToken = async (token) => {
    try {
        const decodedToken = await auth.verifyIdToken(token);
        return decodedToken;
    } catch (error) {
        throw new Error('Invalid or expired token');
    }
};
