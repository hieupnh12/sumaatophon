const pool = require('./db');
pool.query("SELECT customer_id, full_name, phone_number FROM customers WHERE phone_number = '0982481094'")
  .then(([rows]) => {
    console.log(rows);
    process.exit(0);
  })
  .catch(console.error);
