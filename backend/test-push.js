require('dotenv').config({ override: true });
const pool = require('./db');
require('./src/config/firebase');
const { sendPushToCustomer } = require('./src/services/pushNotificationService');

async function main() {
  const customerId = Number(process.argv[2] || 43);
  const result = await sendPushToCustomer(pool, customerId, {
    title: 'Test push PhoneShop',
    body: 'Neu thay thong bao nay thi FCM hoat dong.',
    data: { type: 'test' },
  });
  console.log('Result:', result);
  await pool.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
