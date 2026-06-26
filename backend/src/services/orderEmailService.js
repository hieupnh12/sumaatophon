const nodemailer = require('nodemailer');

const RECEIPT_TAG = 'receiptEmail:';

const SMTP_HOST_BY_DOMAIN = {
  'gmail.com': 'smtp.gmail.com',
  'googlemail.com': 'smtp.gmail.com',
  'outlook.com': 'smtp-mail.outlook.com',
  'hotmail.com': 'smtp-mail.outlook.com',
  'live.com': 'smtp-mail.outlook.com',
  'yahoo.com': 'smtp.mail.yahoo.com',
};

function resolveSmtpConfig() {
  const user = (process.env.MAIL_USERNAME || process.env.SMTP_USER || '').trim();
  const pass = (process.env.MAIL_PASSWORD || process.env.SMTP_PASS || '').trim();
  if (!user || !pass) {
    return null;
  }

  const domain = user.includes('@') ? user.split('@').pop().toLowerCase() : '';
  const host = (process.env.SMTP_HOST || '').trim() || SMTP_HOST_BY_DOMAIN[domain] || 'smtp.gmail.com';
  const port = Number(process.env.SMTP_PORT || 587);
  const from = (process.env.SMTP_FROM || '').trim() || `PhoneShop <${user}>`;

  return { user, pass, host, port, from };
}

function isEmailConfigured() {
  return resolveSmtpConfig() !== null;
}

function parseReceiptFromNote(note) {
  if (!note || typeof note !== 'string') {
    return { wantsReceipt: false, email: null };
  }

  const match = note.match(/receiptEmail:(yes|no)(?::([^|]*))?/i);
  if (!match) {
    return { wantsReceipt: false, email: null };
  }

  const wantsReceipt = match[1].toLowerCase() === 'yes';
  const email = (match[2] || '').trim() || null;
  return { wantsReceipt, email };
}

function formatVnd(amount) {
  return `${Number(amount ?? 0).toLocaleString('vi-VN')} ₫`;
}

function formatPaymentMethod(paymentMethodKey) {
  const map = {
    checkout_payment_qr: 'Chuyển khoản QR (PayOS)',
    checkout_payment_cod: 'Thanh toán khi nhận hàng (COD)',
    checkout_payment_store: 'Thanh toán tại cửa hàng',
  };
  return map[paymentMethodKey] || paymentMethodKey || '—';
}

async function fetchOrderEmailContext(orderId, conn) {
  const [orders] = await conn.query(
  `
      SELECT o.order_id, o.total_amount, o.status, o.note, o.is_paid, o.created_at,
             c.full_name, c.email AS customer_email
      FROM orders o
      LEFT JOIN customers c ON c.customer_id = o.customer_id
      WHERE o.order_id = ?
      LIMIT 1
    `,
    [orderId],
  );

  if (orders.length === 0) return null;

  const [items] = await conn.query(
    `
      SELECT od.quantity, od.unit_price_after,
             p.product_name, pv.version_name, pv.color
      FROM order_details od
      INNER JOIN product_versions pv ON pv.product_version_id = od.product_version_id
      INNER JOIN products p ON p.product_id = pv.product_id
      WHERE od.order_id = ?
    `,
    [orderId],
  );

  const [transactions] = await conn.query(
    `
      SELECT pt.response_message, pm.payment_method_type
      FROM payment_transactions pt
      LEFT JOIN payment_methods pm ON pm.payment_method_id = pt.payment_method_id
      WHERE pt.order_id = ? AND pt.transaction_type = 'PAYMENT'
      ORDER BY pt.payment_time DESC
      LIMIT 1
    `,
    [orderId],
  );

  const order = orders[0];
  const receipt = parseReceiptFromNote(order.note);
  const paymentMethodKey = extractPaymentMethodFromNote(order.note);

  return {
    order,
    items,
    transaction: transactions[0] ?? null,
    receipt,
    paymentMethodKey,
  };
}

function extractPaymentMethodFromNote(note) {
  if (!note) return null;
  for (const key of ['checkout_payment_qr', 'checkout_payment_cod', 'checkout_payment_store']) {
    if (note.includes(key)) return key;
  }
  return null;
}

function buildReceiptHtml({ order, items, paymentMethodKey }) {
  const rows = items
    .map((item) => {
      const name = [item.product_name, item.version_name, item.color].filter(Boolean).join(' — ');
      const lineTotal = Number(item.unit_price_after) * Number(item.quantity);
      return `
        <tr>
          <td style="padding:8px;border-bottom:1px solid #eee;">${name}</td>
          <td style="padding:8px;border-bottom:1px solid #eee;text-align:center;">${item.quantity}</td>
          <td style="padding:8px;border-bottom:1px solid #eee;text-align:right;">${formatVnd(lineTotal)}</td>
        </tr>`;
    })
    .join('');

  const paidAt = order.created_at
    ? new Date(order.created_at).toLocaleString('vi-VN')
    : new Date().toLocaleString('vi-VN');

  return `
    <div style="font-family:Arial,sans-serif;max-width:560px;margin:0 auto;color:#222;">
      <h2 style="color:#1a73e8;">Xác nhận đơn hàng</h2>
      <p>Cảm ơn bạn đã đặt hàng. Đây là <strong>biên lai xác nhận thanh toán/đơn hàng</strong>, không phải hóa đơn VAT điện tử.</p>
      <p><strong>Mã đơn:</strong> #${order.order_id}</p>
      <p><strong>Thời gian:</strong> ${paidAt}</p>
      <p><strong>Phương thức:</strong> ${formatPaymentMethod(paymentMethodKey)}</p>
      <p><strong>Trạng thái:</strong> ${order.is_paid === 1 ? 'Đã thanh toán' : order.status}</p>
      <table style="width:100%;border-collapse:collapse;margin-top:16px;">
        <thead>
          <tr style="background:#f5f5f5;">
            <th style="padding:8px;text-align:left;">Sản phẩm</th>
            <th style="padding:8px;text-align:center;">SL</th>
            <th style="padding:8px;text-align:right;">Thành tiền</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
      <p style="margin-top:16px;font-size:18px;"><strong>Tổng cộng: ${formatVnd(order.total_amount)}</strong></p>
      <p style="font-size:12px;color:#666;margin-top:24px;">Email tự động từ PhoneShop — chỉ dùng cho mục đích xác nhận đơn hàng.</p>
    </div>`;
}

function getMailTransport() {
  const smtp = resolveSmtpConfig();
  if (!smtp) {
    throw new Error('SMTP chưa cấu hình (cần MAIL_USERNAME và MAIL_PASSWORD)');
  }

  return {
    transport: nodemailer.createTransport({
      host: smtp.host,
      port: smtp.port,
      secure: smtp.port === 465,
      auth: { user: smtp.user, pass: smtp.pass },
    }),
    from: smtp.from,
  };
}

async function sendOrderReceiptEmail(orderId, conn) {
  if (!isEmailConfigured()) {
    console.warn('[orderEmail] SMTP chưa cấu hình (MAIL_USERNAME + MAIL_PASSWORD) — bỏ qua gửi email đơn', orderId);
    return { sent: false, reason: 'SMTP_NOT_CONFIGURED' };
  }

  const context = await fetchOrderEmailContext(orderId, conn);
  if (!context) {
    return { sent: false, reason: 'ORDER_NOT_FOUND' };
  }

  const { receipt, order, items, paymentMethodKey } = context;
  if (!receipt.wantsReceipt || !receipt.email) {
    return { sent: false, reason: 'RECEIPT_NOT_REQUESTED' };
  }

  const html = buildReceiptHtml({ order, items, paymentMethodKey });
  const { transport, from } = getMailTransport();

  await transport.sendMail({
    from,
    to: receipt.email,
    subject: `[PhoneShop] Xác nhận đơn hàng #${order.order_id}`,
    html,
    text: `Xác nhận đơn hàng #${order.order_id}. Tổng: ${formatVnd(order.total_amount)}. Đây không phải hóa đơn VAT.`,
  });

  return { sent: true, email: receipt.email };
}

function appendReceiptToNote(note, wantsEmailReceipt, receiptEmail) {
  const base = (note || '')
    .split('|')
    .map((part) => part.trim())
    .filter((part) => part && !part.startsWith(RECEIPT_TAG))
    .join(' | ');

  const receiptPart =
    wantsEmailReceipt === true
      ? `${RECEIPT_TAG}yes:${String(receiptEmail || '').trim()}`
      : `${RECEIPT_TAG}no`;

  return [base, receiptPart].filter(Boolean).join(' | ');
}

module.exports = {
  isEmailConfigured,
  parseReceiptFromNote,
  appendReceiptToNote,
  sendOrderReceiptEmail,
};
