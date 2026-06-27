require('dotenv').config({ override: true });
const pool = require('./db');

async function tableExists(name) {
  const [rows] = await pool.query(
    `SELECT COUNT(*) AS cnt FROM information_schema.tables
     WHERE table_schema = DATABASE() AND table_name = ?`,
    [name],
  );
  return rows[0].cnt > 0;
}

async function rowCount(name) {
  const [rows] = await pool.query(`SELECT COUNT(*) AS n FROM \`${name}\``);
  return rows[0].n;
}

async function main() {
  const tables = [
    'notifications',
    'customers',
    'orders',
    'products',
    'chat_threads',
    'chat_messages',
    'brands',
    'product_versions',
  ];

  console.log('=== KET NOI DB ===');
  const [dbInfo] = await pool.query('SELECT DATABASE() AS db');
  console.log('Database:', dbInfo[0].db);

  console.log('\n=== BANG CAN CHO THONG BAO ===');
  for (const t of tables) {
    const exists = await tableExists(t);
    let count = '-';
    if (exists) count = await rowCount(t);
    console.log(`${exists ? '[OK]' : '[THIEU]'} ${t} (so dong: ${count})`);
  }

  console.log('\n=== CAU TRUC notifications ===');
  if (await tableExists('notifications')) {
    const [cols] = await pool.query('DESCRIBE notifications');
    for (const c of cols) {
      console.log(`  ${c.Field} | ${c.Type} | ${c.Null === 'YES' ? 'NULL' : 'NOT NULL'}`);
    }
    const [sample] = await pool.query(
      `SELECT id, type, title, customer_id, is_read, created_at
       FROM notifications ORDER BY created_at DESC LIMIT 5`,
    );
    console.log('\n  Mau du lieu (5 moi nhat):');
    if (sample.length === 0) console.log('  (chua co thong bao nao)');
    else sample.forEach((r) => console.log('  -', JSON.stringify(r)));
  } else {
    console.log('  Bang CHUA ton tai. Chay npm start de tu tao (initNotificationTables).');
  }

  console.log('\n=== COT QUAN TRONG BANG LIEN QUAN ===');
  const related = {
    customers: ['customer_id', 'full_name', 'phone_number', 'firebase_uid'],
    orders: ['order_id', 'customer_id', 'status', 'total_amount', 'is_paid'],
    products: ['product_id', 'product_name', 'brand_id', 'status'],
    chat_threads: ['id', 'customer_id', 'user_id'],
    chat_messages: ['id', 'thread_id', 'sender_role', 'text', 'is_seen'],
  };

  for (const [table, expectedCols] of Object.entries(related)) {
    if (!(await tableExists(table))) {
      console.log(`${table}: BANG KHONG TON TAI`);
      continue;
    }
    const [cols] = await pool.query(`DESCRIBE \`${table}\``);
    const names = cols.map((c) => c.Field);
    const found = expectedCols.filter((c) => names.includes(c));
    const missing = expectedCols.filter((c) => !names.includes(c));
    console.log(`${table}: OK [${found.join(', ')}]${missing.length ? ` | THIEU [${missing.join(', ')}]` : ''}`);
  }

  console.log('\n=== SAN PHAM DUYET (status=1) ===');
  if (await tableExists('products')) {
    const [approved] = await pool.query('SELECT COUNT(*) AS n FROM products WHERE status = 1');
    const [pending] = await pool.query('SELECT COUNT(*) AS n FROM products WHERE status != 1 OR status IS NULL');
    console.log(`  Da duyet (status=1): ${approved[0].n}`);
    console.log(`  Chua duyet / khac: ${pending[0].n}`);
  }

  console.log('\n=== KET LUAN ===');
  const hasNotifications = await tableExists('notifications');
  const hasCustomers = await tableExists('customers');
  const hasOrders = await tableExists('orders');
  const hasProducts = await tableExists('products');
  const hasChat = (await tableExists('chat_threads')) && (await tableExists('chat_messages'));

  if (hasNotifications && hasCustomers && hasOrders && hasProducts && hasChat) {
    console.log('DB DU dieu kien lam thong bao in-app (3 loai: SP moi, don hang, chat NV).');
  } else {
    console.log('DB THIEU mot so bang — xem chi tiet o tren.');
  }

  await pool.end();
}

main().catch((err) => {
  console.error('LOI:', err.message);
  process.exit(1);
});
