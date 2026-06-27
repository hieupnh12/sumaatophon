const admin = require('firebase-admin');
const serviceAccount = require('../../firebase-service-account.json');
const { getAuth } = require('firebase-admin/auth');

try {
  admin.initializeApp({ credential: admin.cert(serviceAccount) });
  console.log('Firebase Admin initialized successfully.');
} catch (e) {
  console.error('Firebase Admin init error:', e.message);
}

const otpCache = new Map();

module.exports = { getAuth, otpCache };
