const express = require('express');
const pool = require('../../db');
const { getAuth, otpCache } = require('../config/firebase');

const router = express.Router();

function formatDob(birthDate) {
  if (!birthDate) return null;
  return new Date(birthDate.getTime() - birthDate.getTimezoneOffset() * 60000)
    .toISOString()
    .split('T')[0];
}

function mapCustomerUser(user, extra = {}) {
  return {
    id: String(user.customer_id),
    name: user.full_name,
    email: user.email || '',
    phone: user.phone_number || '',
    gender: user.gender,
    dob: formatDob(user.birth_date),
    address: user.address,
    ...extra,
  };
}

// POST /auth/sync — Xác thực Google Token, kiểm tra tài khoản
router.post('/auth/sync', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Missing token' });
    }
    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const firebaseUid = decodedToken.uid;
    const email = decodedToken.email || '';
    const name = decodedToken.name || email.split('@')[0];

    const [existing] = await pool.query('SELECT * FROM customers WHERE firebase_uid = ?', [firebaseUid]);
    if (existing.length > 0) {
      const user = existing[0];
      return res.json({
        id: String(user.customer_id),
        name: user.full_name || name,
        email: user.email || email,
        phone: user.phone_number || '',
        avatarUrl: decodedToken.picture || '',
        gender: user.gender,
        dob: formatDob(user.birth_date),
        address: user.address,
      });
    }

    return res.status(404).json({
      message: 'Vui lòng nhập số điện thoại để hoàn tất',
      code: 'REQUIRE_PHONE_LINK',
    });
  } catch (e) {
    res.status(401).json({ message: e.message });
  }
});

// POST /auth/request-otp — Sinh OTP và gửi qua Cloud Gateway
router.post('/auth/request-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ message: 'Missing phone' });

  const generatedOtp = Math.floor(100000 + Math.random() * 900000).toString();
  otpCache.set(phone, { otp: generatedOtp, expires: Date.now() + 5 * 60 * 1000 });

  try {
    const gatewayUrl = 'https://api.sms-gate.app/3rdparty/v1/messages';
    const authHeader = 'Basic ' + Buffer.from('6S00HR:euqmhd2yd1fbgn').toString('base64');
    const response = await fetch(gatewayUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: authHeader },
      body: JSON.stringify({
        textMessage: { text: `Ma xac thuc PhoneShop cua ban la: ${generatedOtp}` },
        phoneNumbers: [phone.startsWith('0') ? '+84' + phone.substring(1) : phone],
      }),
      signal: AbortSignal.timeout(8000),
    });
    if (!response.ok) throw new Error('SMS Gateway error');
    console.log(`[SMS Gateway Cloud] Gửi SMS thật thành công tới ${phone}`);
    res.json({ message: 'OTP sent successfully via Cloud Gateway' });
  } catch (err) {
    console.log(`[SMS Gateway Error] Tự động Auto-fill. Mã là: ${generatedOtp}`);
    res.json({ message: 'Fallback to dev OTP', devOtp: generatedOtp });
  }
});

// POST /auth/verify-otp — Đăng nhập SĐT thuần túy
router.post('/auth/verify-otp', async (req, res) => {
  const { phone, otp } = req.body;
  console.log(`[Verify OTP] Received phone: ${phone}, otp: ${otp}`);
  const cached = otpCache.get(phone);
  if (!cached || cached.otp !== otp || cached.expires < Date.now()) {
    console.log('[Verify OTP] Failed! Cached:', cached);
    return res.status(400).json({ message: 'Mã OTP không hợp lệ hoặc đã hết hạn.', code: 'INVALID_OTP' });
  }

  const [customers] = await pool.query('SELECT * FROM customers WHERE phone_number = ?', [phone]);
  let customer_id;
  let name = `User ${phone.slice(-4)}`;

  if (customers.length > 0) {
    customer_id = customers[0].customer_id;
    name = customers[0].full_name || name;
  } else {
    const [result] = await pool.query(
      'INSERT INTO customers (full_name, phone_number, create_at, update_at) VALUES (?, ?, NOW(), NOW())',
      [name, phone],
    );
    customer_id = result.insertId;
  }
  otpCache.delete(phone);
  const [finalUser] = await pool.query('SELECT * FROM customers WHERE customer_id = ?', [customer_id]);
  res.json(mapCustomerUser(finalUser[0]));
});

// POST /auth/link-phone — Cập nhật SĐT vào Google ID và xử lý Merge
router.post('/auth/link-phone', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) return res.status(401).json({ message: 'Missing token' });
    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const firebaseUid = decodedToken.uid;
    const email = decodedToken.email || '';

    const { phone, otp, force } = req.body;
    const cached = otpCache.get(phone);
    if (!cached || cached.otp !== otp || cached.expires < Date.now()) {
      return res.status(400).json({ message: 'OTP Invalid', code: 'INVALID_OTP' });
    }

    const [existing] = await pool.query('SELECT * FROM customers WHERE firebase_uid = ?', [firebaseUid]);
    let customer_id;
    const name = decodedToken.name || email.split('@')[0];

    if (existing.length > 0) {
      await pool.query('UPDATE customers SET phone_number = ?, full_name = ? WHERE firebase_uid = ?', [
        phone,
        name,
        firebaseUid,
      ]);
      customer_id = existing[0].customer_id;
    } else {
      const [phoneExists] = await pool.query('SELECT * FROM customers WHERE phone_number = ?', [phone]);
      const [emailExists] = await pool.query('SELECT * FROM customers WHERE email = ?', [email]);

      if (
        phoneExists.length > 0 &&
        emailExists.length > 0 &&
        phoneExists[0].customer_id !== emailExists[0].customer_id
      ) {
        if (force === true) {
          await pool.query('UPDATE customers SET email = NULL, firebase_uid = NULL WHERE customer_id = ?', [
            emailExists[0].customer_id,
          ]);
          await pool.query(
            'UPDATE customers SET firebase_uid = ?, email = ?, full_name = ? WHERE customer_id = ?',
            [firebaseUid, email, name, phoneExists[0].customer_id],
          );
          customer_id = phoneExists[0].customer_id;
        } else {
          return res.status(400).json({
            message:
              'Số điện thoại này đã liên kết với tài khoản khác. Bạn có muốn thay thế bằng tài khoản hiện tại không?',
            code: 'PHONE_CONFLICT',
          });
        }
      } else if (emailExists.length > 0) {
        await pool.query(
          'UPDATE customers SET firebase_uid = ?, phone_number = ?, full_name = ? WHERE customer_id = ?',
          [firebaseUid, phone, name, emailExists[0].customer_id],
        );
        customer_id = emailExists[0].customer_id;
      } else if (phoneExists.length > 0) {
        await pool.query(
          'UPDATE customers SET firebase_uid = ?, email = ?, full_name = ? WHERE customer_id = ?',
          [firebaseUid, email, name, phoneExists[0].customer_id],
        );
        customer_id = phoneExists[0].customer_id;
      } else {
        const [result] = await pool.query(
          'INSERT INTO customers (firebase_uid, full_name, email, phone_number, create_at, update_at) VALUES (?, ?, ?, ?, NOW(), NOW())',
          [firebaseUid, name, email, phone],
        );
        customer_id = result.insertId;
      }
    }
    otpCache.delete(phone);
    const [finalUser] = await pool.query('SELECT * FROM customers WHERE customer_id = ?', [customer_id]);
    res.json(mapCustomerUser(finalUser[0], { avatarUrl: decodedToken.picture || '' }));
  } catch (e) {
    res.status(500).json({ message: e.message, code: 'LINK_PHONE_ERROR' });
  }
});

module.exports = router;
