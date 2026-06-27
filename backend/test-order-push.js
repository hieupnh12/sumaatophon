require('dotenv').config({ override: true });
const pool = require('./db');
require('./src/config/firebase');
const { notifyOrderCreated } = require('./src/services/notificationService');

async function main() {
  const orderId = Number(process.argv[2] || 382);
  const paymentMethod = process.argv[3] || 'STORE';
  const id = await notifyOrderCreated(pool, orderId, paymentMethod);
  console.log('notifyOrderCreated id:', id);
  await pool.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
