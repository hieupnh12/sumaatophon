const { randomUUID } = require('crypto');

const PAYMENT_METHOD_KEYS = {
  checkout_payment_store: 'STORE',
  checkout_payment_cod: 'COD',
  checkout_payment_qr: 'BANK',
};

const PAYMENT_MESSAGES = {
  checkout_payment_store: 'Chờ thanh toán tại cửa hàng',
  checkout_payment_cod: 'Chờ thanh toán khi nhận hàng',
  checkout_payment_qr: 'Chờ thanh toán QR PayOS',
};

async function resolvePaymentMethodId(paymentMethodKey, conn) {
  const methodType = PAYMENT_METHOD_KEYS[paymentMethodKey];
  if (!methodType) {
    throw new Error(`Unsupported payment method: ${paymentMethodKey}`);
  }

  if (resolvePaymentMethodId.cache.has(methodType)) {
    return resolvePaymentMethodId.cache.get(methodType);
  }

  const [rows] = await conn.query(
    'SELECT payment_method_id FROM payment_methods WHERE payment_method_type = ? AND status = 1 LIMIT 1',
    [methodType],
  );

  if (rows.length > 0) {
    resolvePaymentMethodId.cache.set(methodType, rows[0].payment_method_id);
    return rows[0].payment_method_id;
  }

  const provider = methodType === 'STORE' ? 'CASH' : 'VISA';
  const [result] = await conn.query(
    'INSERT INTO payment_methods (payment_method_type, provider, status) VALUES (?, ?, 1)',
    [methodType, provider],
  );
  resolvePaymentMethodId.cache.set(methodType, result.insertId);
  return result.insertId;
}
resolvePaymentMethodId.cache = new Map();

async function createPaymentTransaction({
  conn,
  orderId,
  paymentMethodKey,
  amount,
}) {
  const paymentMethodId = await resolvePaymentMethodId(paymentMethodKey, conn);
  const transactionId = `TXN-${Date.now()}-${orderId}`;
  const transactionCode =
    paymentMethodKey === 'checkout_payment_qr'
      ? `PAYOS-${orderId}`
      : `CODE-${randomUUID().slice(0, 8).toUpperCase()}`;

  await conn.query(
    `
      INSERT INTO payment_transactions (
        transaction_id,
        transaction_code,
        order_id,
        payment_method_id,
        amount_used,
        payment_status,
        transaction_type,
        response_message,
        address
      ) VALUES (?, ?, ?, ?, ?, 'PENDING', 'PAYMENT', ?, ?)
    `,
    [
      transactionId,
      transactionCode,
      orderId,
      paymentMethodId,
      amount,
      PAYMENT_MESSAGES[paymentMethodKey] ?? 'Chờ thanh toán',
      // Địa chỉ giao hàng đầy đủ nằm trong orders.note — cột này chỉ varchar(45).
      null,
    ],
  );

  return { transactionId, transactionCode, paymentMethodId };
}

async function markPaymentSuccess(orderId, responseMessage, conn = null) {
  const db = conn;
  const run = async (connection) => {
    await connection.query(
      `
        UPDATE payment_transactions
        SET payment_status = 'SUCCESS', response_message = ?
        WHERE order_id = ? AND transaction_type = 'PAYMENT'
        ORDER BY payment_time DESC
        LIMIT 1
      `,
      [responseMessage, orderId],
    );
    await connection.query(
      "UPDATE orders SET status = 'PAID', is_paid = 1 WHERE order_id = ?",
      [orderId],
    );

    const { notifyOrderStatusChange } = require('./notificationService');
    try {
      await notifyOrderStatusChange(connection, orderId, 'PAID');
    } catch (err) {
      console.error('[notifications] payment success:', err.message);
    }

    const { sendOrderReceiptEmail } = require('./orderEmailService');
    try {
      await sendOrderReceiptEmail(orderId, connection);
    } catch (err) {
      console.error('[orderEmail] Gửi email sau thanh toán thất bại:', err.message);
    }
  };

  if (db) {
    await run(db);
    return;
  }

  const pool = require('../../db');
  await run(pool);
}

async function markPaymentFailed(orderId, responseMessage, conn) {
  await conn.query(
    `
      UPDATE payment_transactions
      SET payment_status = 'FAILED', response_message = ?
      WHERE order_id = ? AND transaction_type = 'PAYMENT'
      ORDER BY payment_time DESC
      LIMIT 1
    `,
    [responseMessage, orderId],
  );
  await conn.query("UPDATE orders SET status = 'CANCELED', is_paid = 0 WHERE order_id = ?", [orderId]);

  const { notifyOrderStatusChange } = require('./notificationService');
  try {
    await notifyOrderStatusChange(conn, orderId, 'CANCELED');
  } catch (err) {
    console.error('[notifications] payment failed:', err.message);
  }
}

async function revertOrderStock(orderId, conn) {
  const [details] = await conn.query(
    'SELECT order_detail_id FROM order_details WHERE order_id = ?',
    [orderId],
  );

  for (const detail of details) {
    await conn.query(
      "UPDATE product_items SET status = 'IN_STOCK', order_detail_id = NULL WHERE order_detail_id = ?",
      [detail.order_detail_id],
    );
  }
}

module.exports = {
  PAYMENT_METHOD_KEYS,
  PAYMENT_MESSAGES,
  resolvePaymentMethodId,
  createPaymentTransaction,
  markPaymentSuccess,
  markPaymentFailed,
  revertOrderStock,
};
