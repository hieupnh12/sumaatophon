require('dotenv').config({ override: true });
const pool = require('./db');

async function main() {
  const [t] = await pool.query(
    `SELECT COUNT(*) AS n FROM information_schema.tables
     WHERE table_schema = DATABASE() AND table_name = 'fcm_tokens'`,
  );
  console.log('fcm_tokens table exists:', t[0].n > 0);

  if (t[0].n > 0) {
    const [rows] = await pool.query(
      'SELECT customer_id, LEFT(token, 40) AS token_prefix, platform, updated_at FROM fcm_tokens ORDER BY updated_at DESC LIMIT 10',
    );
    console.log('Registered tokens:', rows.length);
    rows.forEach((r) => console.log(' ', r));
  }

  const [n] = await pool.query(
    `SELECT id, type, title, customer_id, created_at FROM notifications
     ORDER BY created_at DESC LIMIT 5`,
  );
  console.log('\nRecent notifications:');
  n.forEach((r) => console.log(' ', r));

  await pool.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
