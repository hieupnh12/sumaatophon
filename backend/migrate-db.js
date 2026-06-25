const pool = require('./db');

async function migrate() {
  try {
    console.log("Checking customers table for firebase_uid...");
    const [columns] = await pool.query(`SHOW COLUMNS FROM customers LIKE 'firebase_uid'`);
    if (columns.length === 0) {
      console.log("Adding firebase_uid to customers table...");
      await pool.query(`ALTER TABLE customers ADD COLUMN firebase_uid VARCHAR(255) UNIQUE AFTER customer_id`);
      console.log("Column added.");
    } else {
      console.log("Column already exists.");
    }
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

migrate();
