const { randomUUID } = require('crypto');

/** Enum orders.status trong DB */
const ORDER_STATUS = {
  PENDING: 'PENDING',
  PAID: 'PAID',
  SHIPPED: 'SHIPPED',
  DELIVERED: 'DELIVERED',
  COMPLETED: 'COMPLETED',
  CANCELED: 'CANCELED',
  RETURNED: 'RETURNED',
};

const ORDER_STATUS_TEXT = {
  PENDING: 'Chờ xử lý',
  PAID: 'Đã thanh toán',
  SHIPPED: 'Đang giao hàng',
  DELIVERED: 'Đã giao hàng',
  COMPLETED: 'Hoàn tất',
  CANCELED: 'Đã hủy',
  RETURNED: 'Đổi trả',
};

const FLUTTER_PAYMENT_KEYS = {
  STORE: 'checkout_payment_store',
  COD: 'checkout_payment_cod',
  BANK: 'checkout_payment_qr',
};

function formatOrderId(orderId) {
  return `#ORD${String(orderId).padStart(6, '0')}`;
}

function paymentKeyFromContext(ctx) {
  const note = ctx?.note ?? '';
  if (note.includes('checkout_payment_qr')) return FLUTTER_PAYMENT_KEYS.BANK;
  if (note.includes('checkout_payment_cod')) return FLUTTER_PAYMENT_KEYS.COD;
  if (note.includes('checkout_payment_store')) return FLUTTER_PAYMENT_KEYS.STORE;

  switch (ctx?.payment_method_type) {
    case 'BANK':
      return FLUTTER_PAYMENT_KEYS.BANK;
    case 'COD':
      return FLUTTER_PAYMENT_KEYS.COD;
    case 'STORE':
      return FLUTTER_PAYMENT_KEYS.STORE;
    default:
      return null;
  }
}

async function getOrderContext(pool, orderId) {
  const [rows] = await pool.query(
    `
      SELECT
        o.order_id,
        o.customer_id,
        o.status,
        o.is_paid,
        o.note,
        pm.payment_method_type,
        pt.payment_status,
        pt.response_message
      FROM orders o
      LEFT JOIN payment_transactions pt
        ON pt.order_id = o.order_id AND pt.transaction_type = 'PAYMENT'
      LEFT JOIN payment_methods pm ON pm.payment_method_id = pt.payment_method_id
      WHERE o.order_id = ?
      ORDER BY pt.payment_time DESC
      LIMIT 1
    `,
    [orderId],
  );
  return rows[0] ?? null;
}

function buildOrderCreatedCopy(paymentKey) {
  switch (paymentKey) {
    case FLUTTER_PAYMENT_KEYS.STORE:
      return {
        titleSuffix: 'Đặt hàng giữ tại cửa hàng',
        body: 'Đơn hàng đã tạo (PENDING). Vui lòng đến cửa hàng thanh toán trong thời gian giữ hàng.',
      };
    case FLUTTER_PAYMENT_KEYS.COD:
      return {
        titleSuffix: 'Đặt hàng COD',
        body: 'Đơn hàng đã tạo (PENDING). Bạn sẽ thanh toán khi nhận hàng.',
      };
    case FLUTTER_PAYMENT_KEYS.BANK:
      return {
        titleSuffix: 'Chờ thanh toán QR',
        body: 'Đơn hàng đã tạo (PENDING). Quét mã QR PayOS để thanh toán.',
      };
    default:
      return {
        titleSuffix: 'Đặt hàng thành công',
        body: 'Đơn hàng của bạn đã được tạo và đang chờ xử lý.',
      };
  }
}

function buildStatusCopy(status, ctx) {
  const paymentKey = paymentKeyFromContext(ctx);
  const formattedId = formatOrderId(ctx.order_id);

  switch (status) {
    case ORDER_STATUS.PAID:
      if (paymentKey === FLUTTER_PAYMENT_KEYS.BANK) {
        return {
          title: `${formattedId} — Thanh toán QR thành công`,
          body: 'PayOS xác nhận thanh toán (SUCCESS). Cửa hàng đang chuẩn bị đơn hàng.',
        };
      }
      return {
        title: `${formattedId} — ${ORDER_STATUS_TEXT.PAID}`,
        body: 'Thanh toán thành công. Cửa hàng đang chuẩn bị đơn hàng.',
      };

    case ORDER_STATUS.SHIPPED:
      return {
        title: `${formattedId} — ${ORDER_STATUS_TEXT.SHIPPED}`,
        body: 'Đơn hàng đang được giao đến bạn.',
      };

    case ORDER_STATUS.DELIVERED:
      if (paymentKey === FLUTTER_PAYMENT_KEYS.COD && ctx.is_paid !== 1) {
        return {
          title: `${formattedId} — Đã giao hàng`,
          body: 'Shipper đã giao hàng. Vui lòng thanh toán COD cho nhân viên giao hàng.',
        };
      }
      return {
        title: `${formattedId} — ${ORDER_STATUS_TEXT.DELIVERED}`,
        body: 'Bạn đã nhận hàng thành công.',
      };

    case ORDER_STATUS.COMPLETED:
      if (paymentKey === FLUTTER_PAYMENT_KEYS.STORE) {
        return {
          title: `${formattedId} — Hoàn tất (cửa hàng)`,
          body: 'Đã thanh toán tại cửa hàng (SUCCESS). Đơn hàng hoàn tất.',
        };
      }
      if (paymentKey === FLUTTER_PAYMENT_KEYS.COD) {
        return {
          title: `${formattedId} — Hoàn tất (COD)`,
          body: 'Đã giao hàng và thu tiền thành công (SUCCESS). Cảm ơn bạn!',
        };
      }
      return {
        title: `${formattedId} — ${ORDER_STATUS_TEXT.COMPLETED}`,
        body: 'Đơn hàng đã hoàn tất. Cảm ơn bạn đã mua sắm!',
      };

    case ORDER_STATUS.CANCELED:
      if (paymentKey === FLUTTER_PAYMENT_KEYS.BANK) {
        return {
          title: `${formattedId} — Thanh toán QR thất bại`,
          body: 'Thanh toán PayOS thất bại hoặc đã hủy (FAILED). Đơn hàng bị hủy, IMEI đã hoàn về kho.',
        };
      }
      return {
        title: `${formattedId} — ${ORDER_STATUS_TEXT.CANCELED}`,
        body: 'Đơn hàng đã bị hủy.',
      };

    case ORDER_STATUS.RETURNED:
      return {
        title: `${formattedId} — ${ORDER_STATUS_TEXT.RETURNED}`,
        body: 'Yêu cầu đổi trả đã được ghi nhận. Bộ phận CSKH sẽ liên hệ bạn.',
      };

    default:
      return {
        title: `${formattedId} — Cập nhật đơn hàng`,
        body: `Trạng thái đơn: ${ORDER_STATUS_TEXT[status] ?? status}.`,
      };
  }
}

function mapRow(row) {
  let payload = null;
  if (row.payload_json) {
    try {
      payload = typeof row.payload_json === 'string'
        ? JSON.parse(row.payload_json)
        : row.payload_json;
    } catch (_) {
      payload = null;
    }
  }

  return {
    id: row.id,
    customerId: row.customer_id != null ? String(row.customer_id) : null,
    type: row.type,
    title: row.title,
    body: row.body,
    payload,
    isRead: Boolean(row.is_read),
    createdAt: row.created_at instanceof Date
      ? row.created_at.toISOString()
      : row.created_at,
  };
}

async function initNotificationTables(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS notifications (
      id VARCHAR(36) PRIMARY KEY,
      customer_id BIGINT NULL,
      type ENUM('product_new', 'order_status', 'chat_message') NOT NULL,
      title VARCHAR(255) NOT NULL,
      body TEXT NOT NULL,
      payload_json JSON NULL,
      is_read TINYINT(1) NOT NULL DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_customer_created (customer_id, created_at),
      INDEX idx_type (type)
    )
  `);
}

async function insertNotification(pool, {
  customerId = null,
  type,
  title,
  body,
  payload = null,
  skipPush = false,
}) {
  const id = randomUUID();
  await pool.query(
    `INSERT INTO notifications (id, customer_id, type, title, body, payload_json)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [
      id,
      customerId,
      type,
      title,
      body,
      payload ? JSON.stringify(payload) : null,
    ],
  );

  if (!skipPush && customerId) {
    const { sendPushToCustomer } = require('./pushNotificationService');
    sendPushToCustomer(pool, customerId, {
      title,
      body,
      data: {
        notificationId: id,
        type,
        ...(payload ?? {}),
      },
    }).catch((err) => console.error('[push] after insert:', err.message));
  }

  return id;
}

async function listForCustomer(pool, customerId, { limit = 50 } = {}) {
  const [rows] = await pool.query(
    `
      SELECT * FROM notifications
      WHERE customer_id = ? OR customer_id IS NULL
      ORDER BY created_at DESC
      LIMIT ?
    `,
    [customerId, limit],
  );
  return rows.map(mapRow);
}

async function countUnread(pool, customerId) {
  const [rows] = await pool.query(
    `
      SELECT COUNT(*) AS total FROM notifications
      WHERE (customer_id = ? OR customer_id IS NULL) AND is_read = 0
    `,
    [customerId],
  );
  return Number(rows[0]?.total ?? 0);
}

async function markRead(pool, notificationId, customerId) {
  const [result] = await pool.query(
    `
      UPDATE notifications
      SET is_read = 1
      WHERE id = ? AND (customer_id = ? OR customer_id IS NULL)
    `,
    [notificationId, customerId],
  );
  return result.affectedRows > 0;
}

async function markAllRead(pool, customerId) {
  await pool.query(
    `
      UPDATE notifications
      SET is_read = 1
      WHERE (customer_id = ? OR customer_id IS NULL) AND is_read = 0
    `,
    [customerId],
  );
}

async function notifyProductPublished(pool, productId) {
  const [products] = await pool.query(
    `
      SELECT p.product_id, p.product_name, b.brand_name,
             (SELECT vi.image FROM product_versions pv
              JOIN version_image vi ON vi.product_version_id = pv.product_version_id
              WHERE pv.product_id = p.product_id LIMIT 1) AS image_url
      FROM products p
      LEFT JOIN brands b ON p.brand_id = b.brand_id
      WHERE p.product_id = ? AND p.status = 1
    `,
    [productId],
  );

  if (products.length === 0) {
    throw new Error('Product not found or not approved');
  }

  const product = products[0];
  const title = `Sản phẩm mới: ${product.product_name}`;
  const body = `${product.brand_name ?? 'PhoneShop'} vừa lên kệ ${product.product_name}. Xem ngay!`;
  const payload = {
    productId: String(product.product_id),
    imageUrl: product.image_url ?? null,
  };

  const [customers] = await pool.query(
    'SELECT customer_id FROM customers WHERE customer_id IS NOT NULL',
  );

  if (customers.length === 0) {
    await insertNotification(pool, {
      customerId: null,
      type: 'product_new',
      title,
      body,
      payload,
    });
    return { sent: 1, mode: 'broadcast' };
  }

  for (const row of customers) {
    await insertNotification(pool, {
      customerId: row.customer_id,
      type: 'product_new',
      title,
      body,
      payload,
    });
  }

  return { sent: customers.length, mode: 'per_customer' };
}

/** Khi tạo đơn — message theo phương thức thanh toán (Store / COD / PayOS). */
async function notifyOrderCreated(pool, orderId, paymentMethodKey, customerId = null) {
  let resolvedCustomerId = customerId;
  if (!resolvedCustomerId) {
    const ctx = await getOrderContext(pool, orderId);
    if (!ctx) return null;
    resolvedCustomerId = ctx.customer_id;
  }

  const formattedId = formatOrderId(orderId);
  const copy = buildOrderCreatedCopy(paymentMethodKey);

  return insertNotification(pool, {
    customerId: resolvedCustomerId,
    type: 'order_status',
    title: `${formattedId} — ${copy.titleSuffix}`,
    body: copy.body,
    payload: {
      orderId: String(orderId),
      status: ORDER_STATUS.PENDING,
      paymentMethod: paymentMethodKey,
      formattedOrderId: formattedId,
    },
  });
}

/** Trạng thái đơn thay đổi — nội dung theo enum DB + phương thức thanh toán. */
async function notifyOrderStatusChange(pool, orderId, status) {
  const ctx = await getOrderContext(pool, orderId);
  if (!ctx) return null;

  const copy = buildStatusCopy(status, ctx);
  const paymentKey = paymentKeyFromContext(ctx);

  return insertNotification(pool, {
    customerId: ctx.customer_id,
    type: 'order_status',
    title: copy.title,
    body: copy.body,
    payload: {
      orderId: String(orderId),
      status,
      paymentMethod: paymentKey,
      isPaid: ctx.is_paid === 1,
      formattedOrderId: formatOrderId(orderId),
    },
  });
}

/**
 * Admin/staff cập nhật trạng thái đơn theo nghiệp vụ:
 * - confirmPayment: COD giao & thu tiền / Store khách trả tại quầy → payment SUCCESS + is_paid=1
 * - markPaid: chỉ cập nhật is_paid (tùy chọn)
 */
async function applyOrderStatusUpdate(pool, {
  orderId,
  status,
  markPaid,
  confirmPayment,
}) {
  const ctx = await getOrderContext(pool, orderId);
  if (!ctx) {
    throw new Error('Order not found');
  }

  const sets = ['status = ?'];
  const params = [status];

  if (markPaid === true) {
    sets.push('is_paid = 1');
  } else if (markPaid === false) {
    sets.push('is_paid = 0');
  }

  if (confirmPayment) {
    sets.push('is_paid = 1');
    await pool.query(
      `
        UPDATE payment_transactions
        SET payment_status = 'SUCCESS',
            response_message = COALESCE(response_message, 'Thanh toán thành công')
        WHERE order_id = ? AND transaction_type = 'PAYMENT'
        ORDER BY payment_time DESC
        LIMIT 1
      `,
      [orderId],
    );
    if (!status || status === ctx.status) {
      status = ORDER_STATUS.COMPLETED;
      sets[0] = 'status = ?';
      params[0] = ORDER_STATUS.COMPLETED;
    }
  }

  await pool.query(
    `UPDATE orders SET ${sets.join(', ')} WHERE order_id = ?`,
    [...params, orderId],
  );

  const notifyStatus = confirmPayment ? ORDER_STATUS.COMPLETED : status;
  return notifyOrderStatusChange(pool, orderId, notifyStatus);
}

async function notifyStaffChatReply(pool, { threadId, customerId, messageText, staffName }) {
  const preview = String(messageText ?? '').trim();
  const short = preview.length > 80 ? `${preview.slice(0, 77)}...` : preview;

  return insertNotification(pool, {
    customerId,
    type: 'chat_message',
    title: staffName ? `${staffName} đã trả lời` : 'Nhân viên đã trả lời',
    body: short || 'Bạn có tin nhắn mới từ bộ phận hỗ trợ.',
    payload: {
      threadId,
      preview: short,
    },
  });
}

module.exports = {
  ORDER_STATUS,
  ORDER_STATUS_TEXT,
  initNotificationTables,
  listForCustomer,
  countUnread,
  markRead,
  markAllRead,
  notifyProductPublished,
  notifyOrderCreated,
  notifyOrderStatusChange,
  applyOrderStatusUpdate,
  notifyStaffChatReply,
  getOrderContext,
  paymentKeyFromContext,
};
