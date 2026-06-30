const express = require('express');
const pool = require('../../db');
const {
  markPaymentSuccess,
  markPaymentFailed,
  revertOrderStock,
} = require('../services/orderPaymentService');
const {
  createPaymentLink,
  verifyWebhook,
  isPayOsConfigured,
  fetchPaymentRequest,
} = require('../services/payosService');
const { removeCartItemsByVersionIds } = require('../services/cartService');

const router = express.Router();

// Trang redirect PayOS (fallback nếu WebView không chặn URL kịp)
router.get('/payment/success', (_req, res) => {
  res
    .status(200)
    .type('html')
    .send(
      '<!DOCTYPE html><html><head><meta charset="utf-8"><title>OK</title></head><body><p>Thanh toán thành công. Bạn có thể quay lại ứng dụng.</p></body></html>',
    );
});

router.get('/payment/cancel', (_req, res) => {
  res
    .status(200)
    .type('html')
    .send(
      '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Cancelled</title></head><body><p>Đã hủy thanh toán. Bạn có thể quay lại ứng dụng.</p></body></html>',
    );
});

async function fetchOrderContext(orderId, conn = pool) {
  const [orders] = await conn.query(
    'SELECT order_id, customer_id, total_amount, status, is_paid FROM orders WHERE order_id = ? LIMIT 1',
    [orderId],
  );
  if (orders.length === 0) return null;

  const [transactions] = await conn.query(
    `
      SELECT payment_status, transaction_code
      FROM payment_transactions
      WHERE order_id = ?
      ORDER BY payment_time DESC
      LIMIT 1
    `,
    [orderId],
  );

  const [details] = await conn.query(
    'SELECT product_version_id FROM order_details WHERE order_id = ?',
    [orderId],
  );

  return {
    order: orders[0],
    transaction: transactions[0] ?? null,
    productVersionIds: details.map((row) => row.product_version_id),
  };
}

// POST /api/payments/payos/create — tạo link thanh toán PayOS cho order đã có trong DB
router.post('/api/payments/payos/create', async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const { orderId, amount, description } = req.body;
    const numericOrderId = Number(orderId);

    if (!numericOrderId || !amount) {
      return res.status(400).json({ message: 'Missing orderId or amount', code: 'MISSING_FIELDS' });
    }

    if (!isPayOsConfigured()) {
      return res.status(503).json({
        message: 'PayOS chưa được cấu hình trên server (PHONESHOP_PAYOS_CLIENT_ID/API_KEY/CHECKSUM_KEY)',
        code: 'PAYOS_NOT_CONFIGURED',
      });
    }

    const context = await fetchOrderContext(numericOrderId, conn);
    if (!context) {
      return res.status(404).json({ message: 'Order not found', code: 'ORDER_NOT_FOUND' });
    }

    if (context.order.is_paid === 1) {
      return res.status(400).json({ message: 'Order already paid', code: 'ORDER_ALREADY_PAID' });
    }

    const paymentLink = await createPaymentLink({
      orderId: numericOrderId,
      amount: Number(amount ?? context.order.total_amount),
      description,
    });

    await conn.query(
      `
        UPDATE payment_transactions
        SET transaction_code = ?
        WHERE order_id = ?
        ORDER BY payment_time DESC
        LIMIT 1
      `,
      [`PAYOS-${numericOrderId}`, numericOrderId],
    );

    res.json({
      checkoutUrl: paymentLink.checkoutUrl,
      qrCode: paymentLink.qrCode,
      paymentLinkId: paymentLink.paymentLinkId,
      orderId: String(numericOrderId),
      amount: Number(amount ?? context.order.total_amount),
    });
  } catch (err) {
    console.error(err);
    const status = err.code === 'PAYOS_NOT_CONFIGURED' ? 503 : 500;
    res.status(status).json({ message: err.message, code: err.code || 'PAYOS_CREATE_ERROR' });
  } finally {
    conn.release();
  }
});

// GET /api/payments/payos/status/:orderId — kiểm tra trạng thái thanh toán trong DB
router.get('/api/payments/payos/status/:orderId', async (req, res) => {
  try {
    const orderId = Number(req.params.orderId);
    const context = await fetchOrderContext(orderId);
    if (!context) {
      return res.status(404).json({ message: 'Order not found', code: 'ORDER_NOT_FOUND' });
    }

    res.json({
      orderId: String(orderId),
      orderStatus: context.order.status,
      isPaid: context.order.is_paid === 1,
      paymentStatus: context.transaction?.payment_status ?? 'PENDING',
    });
  } catch (err) {
    res.status(500).json({ message: err.message, code: 'PAYOS_STATUS_ERROR' });
  }
});

// POST /api/payments/payos/confirm — đồng bộ trạng thái sau khi user quay lại từ PayOS
router.post('/api/payments/payos/confirm', async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const orderId = Number(req.body.orderId);
    if (!orderId) {
      return res.status(400).json({ message: 'Missing orderId', code: 'MISSING_FIELDS' });
    }

    const context = await fetchOrderContext(orderId, conn);
    if (!context) {
      return res.status(404).json({ message: 'Order not found', code: 'ORDER_NOT_FOUND' });
    }

    if (context.order.is_paid === 1) {
      return res.json({
        orderId: String(orderId),
        orderStatus: context.order.status,
        isPaid: true,
        paymentStatus: 'SUCCESS',
      });
    }

    const payosPayment = await fetchPaymentRequest(orderId);
    const isPaid = payosPayment?.status === 'PAID' || payosPayment?.status === 'COMPLETED';

    if (isPaid) {
      await conn.beginTransaction();
      await markPaymentSuccess(
        orderId,
        `Thanh toán thành công qua PayOS. Order Code: ${orderId}`,
        conn,
      );
      await removeCartItemsByVersionIds(
        context.order.customer_id,
        context.productVersionIds,
        conn,
      );
      await conn.commit();
    }

    const updated = await fetchOrderContext(orderId, conn);
    res.json({
      orderId: String(orderId),
      orderStatus: updated?.order.status,
      isPaid: updated?.order.is_paid === 1,
      paymentStatus: updated?.transaction?.payment_status ?? 'PENDING',
    });
  } catch (err) {
    await conn.rollback();
    res.status(500).json({ message: err.message, code: 'PAYOS_CONFIRM_ERROR' });
  } finally {
    conn.release();
  }
});

// POST /api/payments/payos/cancel — user hủy thanh toán trên WebView
router.post('/api/payments/payos/cancel', async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const orderId = Number(req.body.orderId);
    if (!orderId) {
      return res.status(400).json({ message: 'Missing orderId', code: 'MISSING_FIELDS' });
    }

    await conn.beginTransaction();

    const context = await fetchOrderContext(orderId, conn);
    if (!context) {
      await conn.rollback();
      return res.status(404).json({ message: 'Order not found', code: 'ORDER_NOT_FOUND' });
    }

    if (context.order.is_paid === 1) {
      await conn.rollback();
      return res.json({ orderId: String(orderId), status: 'PAID', isPaid: true });
    }

    await markPaymentFailed(orderId, 'Khách hàng hủy thanh toán PayOS', conn);
    await revertOrderStock(orderId, conn);
    await conn.commit();

    res.json({ orderId: String(orderId), status: 'CANCELED', isPaid: false });
  } catch (err) {
    await conn.rollback();
    res.status(500).json({ message: err.message, code: 'PAYOS_CANCEL_ERROR' });
  } finally {
    conn.release();
  }
});

// POST /api/payments/payos/webhook — PayOS gọi khi thanh toán thành công/thất bại
router.post('/api/payments/payos/webhook', async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const { valid, data } = await verifyWebhook(req.body);
    if (!valid || !data) {
      return res.status(400).json({ message: 'Invalid webhook signature', code: 'INVALID_SIGNATURE' });
    }

    const orderCode = Number(data.orderCode);
    if (!orderCode) {
      return res.status(400).json({ message: 'Missing orderCode', code: 'MISSING_ORDER_CODE' });
    }

    await conn.beginTransaction();

    const context = await fetchOrderContext(orderCode, conn);
    if (!context) {
      await conn.rollback();
      return res.status(404).json({ message: 'Order not found', code: 'ORDER_NOT_FOUND' });
    }

    const isSuccess = data.code === '00' || req.body.success === true;

    if (isSuccess) {
      await markPaymentSuccess(
        orderCode,
        `Thanh toán thành công qua PayOS. Order Code: ${orderCode}`,
        conn,
      );
      await removeCartItemsByVersionIds(
        context.order.customer_id,
        context.productVersionIds,
        conn,
      );
    } else {
      await markPaymentFailed(orderCode, data.desc || 'Thanh toán PayOS thất bại', conn);
      await revertOrderStock(orderCode, conn);
    }

    await conn.commit();
    res.json({ success: true });
  } catch (err) {
    await conn.rollback();
    console.error(err);
    res.status(500).json({ message: err.message, code: 'PAYOS_WEBHOOK_ERROR' });
  } finally {
    conn.release();
  }
});

module.exports = router;
