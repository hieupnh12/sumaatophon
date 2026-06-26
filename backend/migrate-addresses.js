const pool = require('./db');

async function migrate() {
  try {
    console.log("Dropping old columns and adding new ones to customer_address_book...");
    
    // Check if column exists before dropping to make it idempotent
    const [cols] = await pool.query(`SHOW COLUMNS FROM customer_address_book LIKE 'address'`);
    if (cols.length > 0) {
      await pool.query(`ALTER TABLE customer_address_book DROP COLUMN address`);
    }

    const newCols = [
      "ADD COLUMN province VARCHAR(100) NOT NULL",
      "ADD COLUMN ward VARCHAR(100) NOT NULL",
      "ADD COLUMN street VARCHAR(255) NOT NULL",
      "ADD COLUMN type VARCHAR(20) NOT NULL DEFAULT 'home'",
      "ADD COLUMN is_default TINYINT(1) NOT NULL DEFAULT 0"
    ];

    for (const col of newCols) {
      try {
        await pool.query(`ALTER TABLE customer_address_book ${col}`);
        console.log(`Successfully ran: ${col}`);
      } catch (err) {
        if (err.code === 'ER_DUP_FIELDNAME') {
          console.log(`Column already exists, skipping: ${col}`);
        } else {
          throw err;
        }
      }
    }
    
    console.log("Migration complete.");
    process.exit(0);
  } catch (err) {
    console.error("Migration failed:", err);
    process.exit(1);
  }
}

migrate();
