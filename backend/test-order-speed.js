require('dotenv').config({ override: true });
const pool = require('./db');

async function main() {
  const [stockRows] = await pool.query(
    `SELECT pv.product_version_id, pv.export_price
     FROM product_versions pv
     JOIN product_items pi ON pi.product_version_id = pv.product_version_id
     WHERE pi.status = 'IN_STOCK' AND pi.order_detail_id IS NULL
     GROUP BY pv.product_version_id, pv.export_price
     HAVING COUNT(*) >= 1
     LIMIT 1`,
  );

  if (stockRows.length === 0) {
    console.log('No stock available');
    await pool.end();
    return;
  }

  const item = stockRows[0];
  const payload = {
    customerId: 43,
    items: [{
      productVersionId: String(item.product_version_id),
      quantity: 1,
      unitPrice: Number(item.export_price),
    }],
    paymentMethod: 'checkout_payment_store',
    deliveryType: 'storePickup',
    address: 'FShop test',
    shippingMethod: 'standard',
    shippingCost: 0,
    subtotal: Number(item.export_price),
    discount: 0,
    total: Number(item.export_price),
    note: '',
    wantsEmailReceipt: false,
  };

  const t0 = Date.now();
  const res = await fetch('http://localhost:3000/api/orders', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const body = await res.text();
  console.log('Status:', res.status, 'Time ms:', Date.now() - t0);
  console.log('Body:', body.slice(0, 200));
  await pool.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
