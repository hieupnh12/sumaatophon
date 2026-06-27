const express = require('express');
const pool = require('../../db');
const {
  initNotificationTables,
  listForCustomer,
  countUnread,
  markRead,
  markAllRead,
  notifyProductPublished,
  applyOrderStatusUpdate,
} = require('../services/notificationService');
const {
  initFcmTokenTable,
  registerFcmToken,
  unregisterFcmToken,
} = require('../services/pushNotificationService');

const router = express.Router();

initNotificationTables(pool).catch((err) => {
  console.error('[notifications] init tables failed:', err.message);
});

initFcmTokenTable(pool).catch((err) => {
  console.error('[notifications] init fcm_tokens failed:', err.message);
});

function parseCustomerId(value) {
  const id = Number(value);
  return Number.isFinite(id) && id > 0 ? id : null;
}

// POST /notifications/register-token
router.post('/notifications/register-token', async (req, res) => {
  try {
    const customerId = parseCustomerId(req.body.customerId);
    const { token, platform } = req.body;
    if (!customerId || !token) {
      return res.status(400).json({ message: 'customerId and token required', code: 'NOTIFICATION_BAD_REQUEST' });
    }
    await registerFcmToken(pool, { customerId, token, platform: platform ?? 'android' });
    console.log(`[push] registered token for customer ${customerId} (${platform ?? 'android'})`);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(400).json({ message: err.message, code: 'FCM_REGISTER_ERROR' });
  }
});

// POST /notifications/unregister-token
router.post('/notifications/unregister-token', async (req, res) => {
  try {
    const customerId = parseCustomerId(req.body.customerId);
    const { token } = req.body;
    await unregisterFcmToken(pool, { customerId, token });
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(400).json({ message: err.message, code: 'FCM_UNREGISTER_ERROR' });
  }
});

// GET /notifications?customerId=81
router.get('/notifications', async (req, res) => {
  try {
    const customerId = parseCustomerId(req.query.customerId);
    if (!customerId) {
      return res.status(400).json({ message: 'Valid customerId required', code: 'NOTIFICATION_BAD_REQUEST' });
    }

    const items = await listForCustomer(pool, customerId);
    const unreadCount = await countUnread(pool, customerId);
    res.json({ items, unreadCount });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'NOTIFICATION_LIST_ERROR' });
  }
});

// GET /notifications/unread-count?customerId=81
router.get('/notifications/unread-count', async (req, res) => {
  try {
    const customerId = parseCustomerId(req.query.customerId);
    if (!customerId) {
      return res.status(400).json({ message: 'Valid customerId required', code: 'NOTIFICATION_BAD_REQUEST' });
    }
    const unreadCount = await countUnread(pool, customerId);
    res.json({ unreadCount });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'NOTIFICATION_COUNT_ERROR' });
  }
});

// PATCH /notifications/:id/read
router.patch('/notifications/:id/read', async (req, res) => {
  try {
    const customerId = parseCustomerId(req.body.customerId ?? req.query.customerId);
    if (!customerId) {
      return res.status(400).json({ message: 'Valid customerId required', code: 'NOTIFICATION_BAD_REQUEST' });
    }

    const ok = await markRead(pool, req.params.id, customerId);
    if (!ok) {
      return res.status(404).json({ message: 'Notification not found', code: 'NOTIFICATION_NOT_FOUND' });
    }
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'NOTIFICATION_READ_ERROR' });
  }
});

// PATCH /notifications/read-all
router.patch('/notifications/read-all', async (req, res) => {
  try {
    const customerId = parseCustomerId(req.body.customerId ?? req.query.customerId);
    if (!customerId) {
      return res.status(400).json({ message: 'Valid customerId required', code: 'NOTIFICATION_BAD_REQUEST' });
    }
    await markAllRead(pool, customerId);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'NOTIFICATION_READ_ALL_ERROR' });
  }
});

/**
 * Admin / hệ thống duyệt sản phẩm → thông báo sản phẩm mới.
 * POST /notifications/triggers/product-published { productId }
 */
router.post('/notifications/triggers/product-published', async (req, res) => {
  try {
    const productId = Number(req.body.productId);
    if (!Number.isFinite(productId) || productId <= 0) {
      return res.status(400).json({ message: 'Valid productId required', code: 'NOTIFICATION_BAD_REQUEST' });
    }
    const result = await notifyProductPublished(pool, productId);
    res.json({ ok: true, ...result });
  } catch (err) {
    console.error(err);
    res.status(400).json({ message: err.message, code: 'NOTIFICATION_TRIGGER_ERROR' });
  }
});

/**
 * Admin/staff cập nhật trạng thái đơn theo nghiệp vụ dự án.
 *
 * POST /notifications/triggers/order-status
 * Body:
 *   { orderId, status }                           — SHIPPED, DELIVERED, RETURNED…
 *   { orderId, status: "COMPLETED", confirmPayment: true } — Store/COD thu tiền xong
 *   { orderId, status: "DELIVERED", markPaid: false }      — COD: giao hàng, chưa thu tiền
 */
router.post('/notifications/triggers/order-status', async (req, res) => {
  try {
    const orderId = Number(req.body.orderId);
    const { status, markPaid, confirmPayment } = req.body;
    if (!Number.isFinite(orderId) || orderId <= 0 || !status) {
      return res.status(400).json({ message: 'orderId and status required', code: 'NOTIFICATION_BAD_REQUEST' });
    }

    const notificationId = await applyOrderStatusUpdate(pool, {
      orderId,
      status,
      markPaid,
      confirmPayment: confirmPayment === true,
    });
    res.json({ ok: true, notificationId });
  } catch (err) {
    console.error(err);
    res.status(400).json({ message: err.message, code: 'NOTIFICATION_TRIGGER_ERROR' });
  }
});

module.exports = router;
