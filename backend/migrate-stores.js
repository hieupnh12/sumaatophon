const pool = require('./db');

const OLD_STORE_NAMES = [
  'phoneShop Premium Q1',
  'phoneShop Mega Mall Q2',
  'phoneShop Hub Q7',
];

const stores = [
  {
    name: 'FShop',
    address: 'X6WQ+R5M, Khu đô thị FPT City, Ngũ Hành Sơn, Đà Nẵng 550000, Việt Nam',
    phone: '02363797979',
    latitude: 15.981042,
    longitude: 108.254771,
    open_time: '08:00 - 22:00',
  },
];

async function migrate() {
  try {
    console.log('Creating stores table if not exists...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS stores (
        store_id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(150) NOT NULL,
        address VARCHAR(255) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        latitude DECIMAL(10, 7) NOT NULL,
        longitude DECIMAL(10, 7) NOT NULL,
        open_time VARCHAR(50) NOT NULL DEFAULT '08:00 - 22:00',
        is_active TINYINT(1) NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    console.log('Removing old mock stores...');
    await pool.query(
      `DELETE FROM stores WHERE name IN (?, ?, ?)`,
      OLD_STORE_NAMES,
    );

    for (const store of stores) {
      const [existing] = await pool.query(
        'SELECT store_id FROM stores WHERE name = ? LIMIT 1',
        [store.name],
      );

      if (existing.length > 0) {
        await pool.query(
          `UPDATE stores
           SET address = ?, phone = ?, latitude = ?, longitude = ?, open_time = ?, is_active = 1
           WHERE store_id = ?`,
          [
            store.address,
            store.phone,
            store.latitude,
            store.longitude,
            store.open_time,
            existing[0].store_id,
          ],
        );
        console.log(`Updated store: ${store.name}`);
        continue;
      }

      await pool.query(
        `INSERT INTO stores (name, address, phone, latitude, longitude, open_time, is_active)
         VALUES (?, ?, ?, ?, ?, ?, 1)`,
        [
          store.name,
          store.address,
          store.phone,
          store.latitude,
          store.longitude,
          store.open_time,
        ],
      );
      console.log(`Inserted store: ${store.name}`);
    }

    const [rows] = await pool.query(
      'SELECT store_id, name, address FROM stores WHERE is_active = 1 ORDER BY store_id',
    );
    console.log('Active stores:', rows);

    console.log('Migration complete.');
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(1);
  }
}

migrate();
