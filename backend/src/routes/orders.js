const express = require('express');
const pool = require('../../db');
const { fetchVersionStock, clearCustomerCart } = require('../services/cartService');

const router = express.Router();

// POST /api/orders — tạo đơn, gán IMEI (product_items) và đánh dấu SOLD
router.post('/api/orders', async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const {
      customerId,
      items,
      address,
      shippingMethod,
      shippingCost,
      paymentMethod,
      subtotal,
      discount,
      total,
      note,
    } = req.body;

    if (!customerId || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Missing customerId or items', code: 'MISSING_FIELDS' });
    }

    await conn.beginTransaction();

    const orderTotal = Number(total ?? subtotal ?? 0);
    const orderNote = [address, shippingMethod, paymentMethod, note].filter(Boolean).join(' | ');

    const [orderResult] = await conn.query(
      'INSERT INTO orders (customer_id, total_amount, status, note, is_paid) VALUES (?, ?, ?, ?, ?)',
      [customerId, orderTotal, 'PENDING', orderNote || null, paymentMethod === 'checkout_payment_cod' ? 0 : 0],
    );
    const orderId = orderResult.insertId;

    for (const item of items) {
      const productVersionId = item.productVersionId;
      const quantity = Number(item.quantity ?? 1);
      const unitPrice = Number(item.unitPrice ?? 0);

      const stock = await fetchVersionStock(productVersionId, conn);
      if (quantity > stock) {
        throw new Error(`Insufficient IMEI stock for version ${productVersionId}`);
      }

      const [detailResult] = await conn.query(
        'INSERT INTO order_details (order_id, product_version_id, unit_price_before, unit_price_after, quantity) VALUES (?, ?, ?, ?, ?)',
        [orderId, productVersionId, unitPrice, unitPrice, quantity],
      );
      const orderDetailId = detailResult.insertId;

      const [availableImeis] = await conn.query(
        `
          SELECT imei FROM product_items
          WHERE product_version_id = ?
            AND status = 'IN_STOCK'
            AND order_detail_id IS NULL
          ORDER BY imei
          LIMIT ?
        `,
        [productVersionId, quantity],
      );

      for (const row of availableImeis) {
        await conn.query("UPDATE product_items SET status = 'SOLD', order_detail_id = ? WHERE imei = ?", [
          orderDetailId,
          row.imei,
        ]);
      }
    }

    await clearCustomerCart(customerId, conn);
    await conn.commit();

    res.json({
      id: String(orderId),
      status: 'PENDING',
      total: orderTotal,
      shippingCost: Number(shippingCost ?? 0),
      discount: Number(discount ?? 0),
    });
  } catch (err) {
    await conn.rollback();
    console.error(err);
    res.status(400).json({ message: err.message, code: 'ORDER_CREATE_ERROR' });
  } finally {
    conn.release();
  }
});

module.exports = router;
