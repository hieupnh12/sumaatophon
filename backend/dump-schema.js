const pool = require('./db');

async function dumpSchema() {
  try {
    const [tables] = await pool.query('SHOW TABLES');
    const tableKey = Object.keys(tables[0])[0]; // e.g. "Tables_in_phoneShop"
    
    for (const tableObj of tables) {
      const tableName = tableObj[tableKey];
      console.log(`\n--- TABLE: ${tableName} ---`);
      const [columns] = await pool.query(`DESCRIBE \`${tableName}\``);
      columns.forEach(col => {
        console.log(`  ${col.Field} | ${col.Type} | Null: ${col.Null} | Key: ${col.Key} | Default: ${col.Default} | Extra: ${col.Extra}`);
      });
    }
    
    process.exit(0);
  } catch (err) {
    console.error("Error dumping schema:", err);
    process.exit(1);
  }
}

dumpSchema();
