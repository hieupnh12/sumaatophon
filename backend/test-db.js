require('dotenv').config({ override: true });

async function main() {
  console.log('Testing MySQL (Aiven)...');
  console.log('  host:', process.env.DB_HOST);
  console.log('  port:', process.env.DB_PORT);
  console.log('  user:', process.env.DB_USER);
  console.log('  database:', process.env.DB_NAME);
  console.log('  password length:', (process.env.DB_PASSWORD || '').length);

  try {
    const pool = require('./db');
    const [rows] = await pool.query('SELECT DATABASE() AS db, USER() AS user');
    console.log('OK:', rows[0]);
    await pool.end();
    process.exit(0);
  } catch (err) {
    console.error('FAIL:', err.message);
    if (err.message.includes('Access denied')) {
      console.error('');
      console.error('Fix on Aiven Console:');
      console.error('  1. Users -> avnadmin -> Reset password -> copy vao backend/.env');
      console.error('  2. Allowed IP -> them IP trong loi (hoa 0.0.0.0/0 khi dev)');
      console.error('  3. Restart: npm start');
    }
    process.exit(1);
  }
}

main();
