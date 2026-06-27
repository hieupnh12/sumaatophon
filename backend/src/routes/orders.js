const express = require('express');
const pool = require('../../db');
const {
  fetchVersionStock,
  clearCustomerCart,
  removeCartItemsByVersionIds,
} = require('../services/cartService');
const { createPaymentTransaction } = require('../services/orderPaymentService');
const { appendReceiptToNote, sendOrderReceiptEmail } = require('../services/orderEmailService');

const router = express.Router();

const SUPPORTED_PAYMENT_METHODS = new Set([
  'checkout_payment_store',
  'checkout_payment_cod',
  'checkout_payment_qr',
]);

function buildOrderNote({ address, shippingMethod, paymentMethod, note, deliveryType }) {
  return [address, shippingMethod, deliveryType, paymentMethod, note].filter(Boolean).join(' | ');
}

// POST /api/orders — tạo đơn, gán IMEI (product_items), payment_transactions
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
      deliveryType,
      subtotal,
      discount,
      total,
      note,
      wantsEmailReceipt,
      receiptEmail,
    } = req.body;

    if (!customerId || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Missing customerId or items', code: 'MISSING_FIELDS' });
    }

    if (!SUPPORTED_PAYMENT_METHODS.has(paymentMethod)) {
      return res.status(400).json({ message: 'Unsupported payment method', code: 'INVALID_PAYMENT_METHOD' });
    }

    await conn.beginTransaction();

    const orderTotal = Number(total ?? subtotal ?? 0);
    const orderNote = appendReceiptToNote(
      buildOrderNote({
        address,
        shippingMethod,
        paymentMethod,
        note,
        deliveryType,
      }),
      wantsEmailReceipt,
      receiptEmail,
    );
    const isQrPayment = paymentMethod === 'checkout_payment_qr';

    const [orderResult] = await conn.query(
      'INSERT INTO orders (customer_id, total_amount, status, note, is_paid) VALUES (?, ?, ?, ?, ?)',
      [customerId, orderTotal, 'PENDING', orderNote || null, 0],
    );
    const orderId = orderResult.insertId;

    const orderedVersionIds = [];

    for (const item of items) {
      const productVersionId = item.productVersionId;
      const quantity = Number(item.quantity ?? 1);
      const unitPrice = Number(item.unitPrice ?? 0);
      orderedVersionIds.push(productVersionId);

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

      if (availableImeis.length < quantity) {
        throw new Error(`Insufficient IMEI stock for version ${productVersionId}`);
      }

      for (const row of availableImeis) {
        await conn.query(
          "UPDATE product_items SET status = 'SOLD', order_detail_id = ? WHERE imei = ?",
          [orderDetailId, row.imei],
        );
      }
    }

    await createPaymentTransaction({
      conn,
      orderId,
      paymentMethodKey: paymentMethod,
      amount: orderTotal,
    });

    if (isQrPayment) {
      // QR: chỉ xóa cart sau khi PayOS webhook xác nhận thành công.
    } else {
      await removeCartItemsByVersionIds(customerId, orderedVersionIds, conn);
    }

    await conn.commit();

    if (!isQrPayment && wantsEmailReceipt === true) {
      try {
        await sendOrderReceiptEmail(orderId, conn);
      } catch (err) {
        console.error('[orderEmail] Gửi email xác nhận đơn thất bại:', err.message);
      }
    }

    res.json({
      id: String(orderId),
      orderId,
      status: 'PENDING',
      isPaid: false,
      paymentMethod,
      total: orderTotal,
      shippingCost: Number(shippingCost ?? 0),
      discount: Number(discount ?? 0),
      requiresPayOs: isQrPayment,
    });
  } catch (err) {
    await conn.rollback();
    console.error(err);
    res.status(400).json({ message: err.message, code: 'ORDER_CREATE_ERROR' });
  } finally {
    conn.release();
  }
});

// GET /api/orders
router.get('/api/orders', require('../../orders/orders.controller').getOrders);

// GET /api/orders/:id
router.get('/api/orders/:id', require('../../orders/orders.controller').getOrderDetails);

module.exports = router;
