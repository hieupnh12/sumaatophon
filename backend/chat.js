const { randomUUID } = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

const CHAT_IMAGE_ONLY_TEXT = '📷';

const chatUploadDir = path.join(__dirname, 'uploads', 'chat');
fs.mkdirSync(chatUploadDir, { recursive: true });

const chatImageUpload = multer({
  storage: multer.diskStorage({
    destination: chatUploadDir,
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname || '').toLowerCase() || '.jpg';
      const safeExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext) ? ext : '.jpg';
      cb(null, `${Date.now()}-${randomUUID()}${safeExt}`);
    },
  }),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (!file.mimetype || !file.mimetype.startsWith('image/')) {
      cb(new Error('Only image files are allowed'));
      return;
    }
    cb(null, true);
  },
});

function normalizeChatMessagePayload(text, imageUrl) {
  const trimmed = String(text ?? '').trim();
  const url = imageUrl ? String(imageUrl).trim() : null;
  if (!trimmed && !url) return null;
  return {
    text: trimmed || CHAT_IMAGE_ONLY_TEXT,
    imageUrl: url,
  };
}

function toUtcIso(value) {
  if (!value) return null;
  if (value instanceof Date) return value.toISOString();
  const raw = String(value).trim();
  if (!raw) return null;
  if (raw.endsWith('Z') || /[+-]\d{2}:\d{2}$/.test(raw)) {
    return new Date(raw).toISOString();
  }
  return new Date(`${raw.replace(' ', 'T')}Z`).toISOString();
}

async function initChatTables(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS chat_threads (
      id VARCHAR(36) PRIMARY KEY,
      customer_id BIGINT NOT NULL,
      user_id VARCHAR(64) NOT NULL,
      user_name VARCHAR(255) NOT NULL,
      user_email VARCHAR(255) NULL,
      user_phone VARCHAR(32) NULL,
      user_avatar VARCHAR(512) NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY uk_customer (customer_id),
      UNIQUE KEY uk_user (user_id)
    )
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS chat_messages (
      id VARCHAR(36) PRIMARY KEY,
      thread_id VARCHAR(36) NOT NULL,
      sender_id VARCHAR(64) NOT NULL,
      sender_role ENUM('user', 'admin') NOT NULL,
      text TEXT NOT NULL,
      image_url VARCHAR(512) NULL,
      is_seen TINYINT(1) NOT NULL DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_thread (thread_id),
      INDEX idx_created (created_at)
    )
  `);

  // Migration cho bảng cũ thiếu cột
  const migrations = [
    'ALTER TABLE chat_threads ADD COLUMN customer_id BIGINT NULL AFTER id',
    'ALTER TABLE chat_threads ADD COLUMN user_phone VARCHAR(32) NULL AFTER user_email',
  ];
  for (const sql of migrations) {
    try {
      await pool.query(sql);
    } catch (_) {
      /* column exists */
    }
  }
}

function mapMessage(row) {
  return {
    id: row.id,
    threadId: row.thread_id,
    senderId: row.sender_id,
    senderRole: row.sender_role,
    text: row.text,
    imageUrl: row.image_url ?? null,
    isSeen: Boolean(row.is_seen),
    createdAt: toUtcIso(row.created_at),
  };
}

function mapThread(row) {
  const name = row.customer_full_name ?? row.user_name ?? 'Khách hàng';
  const email = row.customer_email ?? row.user_email ?? '';
  const phone = row.customer_phone ?? row.user_phone ?? null;

  return {
    id: row.id,
    customerId: String(row.customer_id ?? row.user_id),
    userId: String(row.customer_id ?? row.user_id),
    userName: name,
    userEmail: email,
    userPhone: phone,
    userAvatar: row.user_avatar ?? null,
    lastMessage: row.last_message ?? null,
    lastMessageAt: toUtcIso(row.last_message_at),
    unreadCount: Number(row.unread_count ?? 0),
    updatedAt: toUtcIso(row.updated_at),
  };
}

function parseCustomerId(raw) {
  const id = Number(raw);
  if (!Number.isFinite(id) || id <= 0) return null;
  return id;
}

async function loadCustomer(pool, customerId) {
  const [rows] = await pool.query(
    'SELECT customer_id, full_name, email, phone_number FROM customers WHERE customer_id = ? LIMIT 1',
    [customerId],
  );
  if (rows.length === 0) {
    throw new Error('Khách hàng không tồn tại trong hệ thống');
  }
  return rows[0];
}

async function getOrCreateThreadForCustomer(pool, customerId) {
  const customer = await loadCustomer(pool, customerId);
  const idKey = String(customer.customer_id);

  const [existing] = await pool.query(
    'SELECT * FROM chat_threads WHERE customer_id = ? OR user_id = ? LIMIT 1',
    [customer.customer_id, idKey],
  );

  if (existing.length > 0) {
    await pool.query(
      `UPDATE chat_threads
       SET customer_id = ?, user_id = ?, user_name = ?, user_email = ?, user_phone = ?, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [
        customer.customer_id,
        idKey,
        customer.full_name ?? 'Khách hàng',
        customer.email ?? '',
        customer.phone_number ?? null,
        existing[0].id,
      ],
    );
    const [updated] = await pool.query('SELECT * FROM chat_threads WHERE id = ?', [existing[0].id]);
    return updated[0];
  }

  const id = randomUUID();
  await pool.query(
    `INSERT INTO chat_threads (id, customer_id, user_id, user_name, user_email, user_phone)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [
      id,
      customer.customer_id,
      idKey,
      customer.full_name ?? 'Khách hàng',
      customer.email ?? '',
      customer.phone_number ?? null,
    ],
  );

  const [rows] = await pool.query('SELECT * FROM chat_threads WHERE id = ?', [id]);
  return rows[0];
}

async function listThreadsForAdmin(pool) {
  const [rows] = await pool.query(`
    SELECT
      t.*,
      c.full_name AS customer_full_name,
      c.email AS customer_email,
      c.phone_number AS customer_phone,
      lm.text AS last_message,
      lm.created_at AS last_message_at,
      (
        SELECT COUNT(*)
        FROM chat_messages m
        WHERE m.thread_id = t.id
          AND m.sender_role = 'user'
          AND m.is_seen = 0
      ) AS unread_count
    FROM chat_threads t
    INNER JOIN customers c ON c.customer_id = t.customer_id
    LEFT JOIN chat_messages lm ON lm.id = (
      SELECT id FROM chat_messages
      WHERE thread_id = t.id
      ORDER BY created_at DESC
      LIMIT 1
    )
    ORDER BY COALESCE(lm.created_at, t.updated_at) DESC
  `);

  return rows.map(mapThread);
}

async function getMessages(pool, threadId) {
  const [rows] = await pool.query(
    `SELECT * FROM chat_messages WHERE thread_id = ? ORDER BY created_at ASC`,
    [threadId],
  );
  return rows.map(mapMessage);
}

async function insertMessage(pool, { threadId, senderId, senderRole, text, imageUrl }) {
  const id = randomUUID();
  await pool.query(
    `INSERT INTO chat_messages (id, thread_id, sender_id, sender_role, text, image_url)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [id, threadId, senderId, senderRole, text, imageUrl ?? null],
  );

  await pool.query('UPDATE chat_threads SET updated_at = CURRENT_TIMESTAMP WHERE id = ?', [threadId]);

  const [rows] = await pool.query('SELECT * FROM chat_messages WHERE id = ?', [id]);
  return mapMessage(rows[0]);
}

function isSupportStaff(userOrRole) {
  if (typeof userOrRole === 'string') {
    return userOrRole === 'admin' || userOrRole === 'staff';
  }
  const user = userOrRole;
  return (
    user.accountType === 'employee' ||
    user.role === 'admin' ||
    user.role === 'staff'
  );
}

function isStaffQuery(query) {
  return isSupportStaff(query.role) || query.accountType === 'employee';
}

async function markThreadSeen(pool, threadId, viewerRole) {
  const senderRole = isSupportStaff(viewerRole) ? 'user' : 'admin';
  await pool.query(
    `UPDATE chat_messages SET is_seen = 1
     WHERE thread_id = ? AND sender_role = ? AND is_seen = 0`,
    [threadId, senderRole],
  );
}

function parseUserFromQuery(query) {
  const userId = query.userId;
  const role = query.role;
  const accountType =
    query.accountType ?? (role === 'admin' || role === 'staff' ? 'employee' : 'customer');

  if (!userId || !role || !['user', 'admin', 'staff'].includes(role)) {
    return null;
  }

  return {
    userId,
    role,
    accountType,
    userName: query.userName ?? 'User',
    userEmail: query.userEmail ?? '',
    userAvatar: query.userAvatar ?? null,
  };
}

function setupChat(app, io, pool) {
  initChatTables(pool).catch((err) => {
    console.error('Failed to init chat tables:', err.message);
  });

  app.get('/chat/threads', async (req, res) => {
    try {
      if (!isStaffQuery(req.query)) {
        return res.status(403).json({ message: 'Staff only', code: 'CHAT_FORBIDDEN' });
      }
      const threads = await listThreadsForAdmin(pool);
      res.json(threads);
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: err.message, code: 'CHAT_THREADS_ERROR' });
    }
  });

  app.get('/chat/threads/mine', async (req, res) => {
    try {
      const customerId = parseCustomerId(req.query.customerId ?? req.query.userId);
      if (!customerId) {
        return res.status(400).json({
          message: 'Valid customerId required — please sign in with your account',
          code: 'CHAT_BAD_REQUEST',
        });
      }

      const threadRow = await getOrCreateThreadForCustomer(pool, customerId);
      res.json(mapThread({ ...threadRow, last_message: null, last_message_at: null, unread_count: 0 }));
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: err.message, code: 'CHAT_THREAD_ERROR' });
    }
  });

  app.post('/chat/upload-image', (req, res) => {
    chatImageUpload.single('image')(req, res, (err) => {
      if (err) {
        const message = err.code === 'LIMIT_FILE_SIZE'
          ? 'Image must be 5MB or smaller'
          : err.message;
        return res.status(400).json({ message, code: 'CHAT_UPLOAD_ERROR' });
      }
      if (!req.file) {
        return res.status(400).json({ message: 'No image file', code: 'CHAT_UPLOAD_ERROR' });
      }
      res.json({ imageUrl: `/uploads/chat/${req.file.filename}` });
    });
  });

  app.get('/chat/threads/:threadId/messages', async (req, res) => {
    try {
      const messages = await getMessages(pool, req.params.threadId);
      const viewerRole = req.query.role;
      if (viewerRole) {
        await markThreadSeen(pool, req.params.threadId, viewerRole);
      }
      res.json(messages);
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: err.message, code: 'CHAT_MESSAGES_ERROR' });
    }
  });

  /** Gửi tin qua REST (web admin + app fallback khi Socket.IO lỗi) */
  app.post('/chat/threads/:threadId/messages', async (req, res) => {
    try {
      const threadId = req.params.threadId;
      const normalized = normalizeChatMessagePayload(req.body?.text, req.body?.imageUrl);

      if (!threadId || !normalized) {
        return res.status(400).json({
          message: 'threadId and text or imageUrl are required',
          code: 'CHAT_BAD_REQUEST',
        });
      }

      const { text, imageUrl } = normalized;

      const isStaff = isStaffQuery(req.query);
      const customerId = parseCustomerId(req.body?.customerId ?? req.query.customerId);

      let message;
      if (isStaff) {
        const staffId = String(req.body?.staffId ?? req.query.userId ?? '').trim();
        const staffName = String(req.body?.staffName ?? req.query.userName ?? 'Nhân viên').trim();
        if (!staffId) {
          return res.status(400).json({ message: 'staffId is required', code: 'CHAT_BAD_REQUEST' });
        }
        message = await insertMessage(pool, {
          threadId,
          senderId: staffId,
          senderRole: 'admin',
          text,
          imageUrl,
        });
        try {
          const [threadRows] = await pool.query(
            'SELECT customer_id FROM chat_threads WHERE id = ?',
            [threadId],
          );
          if (threadRows[0]?.customer_id) {
            const { notifyStaffChatReply } = require('./src/services/notificationService');
            await notifyStaffChatReply(pool, {
              threadId,
              customerId: threadRows[0].customer_id,
              messageText: text,
              staffName,
            });
          }
        } catch (notifyErr) {
          console.error('[notifications] staff chat reply (REST):', notifyErr.message);
        }
      } else if (customerId) {
        const [threadRows] = await pool.query(
          'SELECT customer_id FROM chat_threads WHERE id = ?',
          [threadId],
        );
        if (!threadRows.length || Number(threadRows[0].customer_id) !== customerId) {
          return res.status(403).json({ message: 'Thread access denied', code: 'CHAT_FORBIDDEN' });
        }
        message = await insertMessage(pool, {
          threadId,
          senderId: String(customerId),
          senderRole: 'user',
          text,
          imageUrl,
        });
      } else {
        return res.status(403).json({ message: 'Staff or customer auth required', code: 'CHAT_FORBIDDEN' });
      }

      io.to(`thread:${threadId}`).emit('new_message', message);
      const threads = await listThreadsForAdmin(pool);
      io.to('admin:inbox').emit('threads_updated', threads);

      res.status(201).json(message);
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: err.message, code: 'CHAT_SEND_ERROR' });
    }
  });

  io.on('connection', (socket) => {
    const user = parseUserFromQuery(socket.handshake.query);
    if (!user) {
      console.warn('[chat] socket rejected: missing/invalid query', socket.handshake.query);
      socket.disconnect(true);
      return;
    }

    socket.data.user = user;
    console.log(`[chat] socket connected userId=${user.userId} role=${user.role} accountType=${user.accountType}`);

    if (isSupportStaff(user)) {
      socket.join('admin:inbox');
    } else if (user.accountType === 'customer') {
      void (async () => {
        try {
          const threadRow = await getOrCreateThreadForCustomer(pool, Number(user.userId));
          socket.data.threadId = threadRow.id;
          socket.join(`thread:${threadRow.id}`);
        } catch (err) {
          console.error('[chat] customer join error:', err.message);
          socket.disconnect(true);
        }
      })();
    }

    socket.on('join_thread', async (payload, ack) => {
      if (!isSupportStaff(user) || !payload?.threadId) {
        if (typeof ack === 'function') ack({ ok: false });
        return;
      }
      socket.data.threadId = payload.threadId;
      socket.join(`thread:${payload.threadId}`);
      try {
        await markThreadSeen(pool, payload.threadId, 'staff');
        if (typeof ack === 'function') ack({ ok: true });
      } catch (err) {
        if (typeof ack === 'function') ack({ ok: false, message: err.message });
      }
    });

    socket.on('send_message', async (payload, ack) => {
      try {
        let threadId = payload?.threadId ?? socket.data.threadId;

        if (!threadId && user.role === 'user' && user.accountType === 'customer') {
          const threadRow = await getOrCreateThreadForCustomer(pool, Number(user.userId));
          threadId = threadRow.id;
          socket.data.threadId = threadId;
          socket.join(`thread:${threadId}`);
        }

        const normalized = normalizeChatMessagePayload(payload?.text, payload?.imageUrl);
        if (!threadId || !normalized) {
          if (typeof ack === 'function') ack({ ok: false, message: 'Invalid message' });
          return;
        }

        const { text, imageUrl } = normalized;

        const message = await insertMessage(pool, {
          threadId,
          senderId: user.userId,
          senderRole: isSupportStaff(user) ? 'admin' : 'user',
          text,
          imageUrl,
        });

        if (isSupportStaff(user)) {
          try {
            const [threadRows] = await pool.query(
              'SELECT customer_id FROM chat_threads WHERE id = ?',
              [threadId],
            );
            if (threadRows[0]?.customer_id) {
              const { notifyStaffChatReply } = require('./src/services/notificationService');
              await notifyStaffChatReply(pool, {
                threadId,
                customerId: threadRows[0].customer_id,
                messageText: text,
                staffName: user.userName,
              });
            }
          } catch (notifyErr) {
            console.error('[notifications] staff chat reply:', notifyErr.message);
          }
        }

        io.to(`thread:${threadId}`).emit('new_message', message);

        const threads = await listThreadsForAdmin(pool);
        io.to('admin:inbox').emit('threads_updated', threads);

        if (typeof ack === 'function') ack({ ok: true, message });
      } catch (err) {
        console.error('send_message error:', err);
        if (typeof ack === 'function') ack({ ok: false, message: err.message });
      }
    });

    socket.on('disconnect', () => { });
  });
}

module.exports = { setupChat, initChatTables };
