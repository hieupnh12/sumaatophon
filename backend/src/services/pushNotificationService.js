const { randomUUID } = require('crypto');
require('../config/firebase');
const { getMessaging } = require('firebase-admin/messaging');

async function initFcmTokenTable(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS fcm_tokens (
      id VARCHAR(36) PRIMARY KEY,
      customer_id BIGINT NOT NULL,
      token VARCHAR(512) NOT NULL,
      platform VARCHAR(16) NOT NULL DEFAULT 'android',
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY uk_fcm_token (token),
      INDEX idx_fcm_customer (customer_id)
    )
  `);
}

async function registerFcmToken(pool, { customerId, token, platform = 'android' }) {
  if (!customerId || !token) {
    throw new Error('customerId and token required');
  }

  const [existing] = await pool.query(
    'SELECT id, customer_id FROM fcm_tokens WHERE token = ?',
    [token],
  );

  if (existing.length > 0) {
    await pool.query(
      'UPDATE fcm_tokens SET customer_id = ?, platform = ?, updated_at = CURRENT_TIMESTAMP WHERE token = ?',
      [customerId, platform, token],
    );
    return existing[0].id;
  }

  const id = randomUUID();
  await pool.query(
    'INSERT INTO fcm_tokens (id, customer_id, token, platform) VALUES (?, ?, ?, ?)',
    [id, customerId, token, platform],
  );
  return id;
}

async function unregisterFcmToken(pool, { customerId, token }) {
  if (token) {
    await pool.query('DELETE FROM fcm_tokens WHERE token = ?', [token]);
    return;
  }
  if (customerId) {
    await pool.query('DELETE FROM fcm_tokens WHERE customer_id = ?', [customerId]);
  }
}

async function getTokensForCustomer(pool, customerId) {
  const [rows] = await pool.query(
    'SELECT token FROM fcm_tokens WHERE customer_id = ?',
    [customerId],
  );
  return rows.map((r) => r.token);
}

async function removeInvalidTokens(pool, tokens) {
  if (!tokens.length) return;
  const placeholders = tokens.map(() => '?').join(',');
  await pool.query(`DELETE FROM fcm_tokens WHERE token IN (${placeholders})`, tokens);
}

async function sendPushToCustomer(pool, customerId, { title, body, data = {} }) {
  if (!customerId || !title) return { sent: 0 };

  const tokens = await getTokensForCustomer(pool, customerId);
  if (tokens.length === 0) {
    console.log(`[push] skip customer ${customerId}: no FCM tokens registered`);
    return { sent: 0, reason: 'no_tokens' };
  }

  const dataPayload = Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, v == null ? '' : String(v)]),
  );

  try {
    const messaging = getMessaging();
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body: body ?? '' },
      data: dataPayload,
      android: {
        priority: 'high',
        notification: {
          channelId: 'phoneshop_notifications',
          priority: 'high',
        },
      },
    });

    const invalidTokens = [];
    response.responses.forEach((res, index) => {
      if (!res.success) {
        const code = res.error?.code;
        if (
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered'
        ) {
          invalidTokens.push(tokens[index]);
        }
      }
    });
    await removeInvalidTokens(pool, invalidTokens);

    console.log(
      `[push] customer ${customerId}: sent=${response.successCount} failed=${response.failureCount}`,
    );
    return { sent: response.successCount, failed: response.failureCount };
  } catch (err) {
    console.error('[push] send error:', err.message);
    return { sent: 0, error: err.message };
  }
}

module.exports = {
  initFcmTokenTable,
  registerFcmToken,
  unregisterFcmToken,
  sendPushToCustomer,
};
