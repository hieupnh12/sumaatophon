const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

function splitPipe(value) {
  if (!value) return [];
  return String(value)
    .split('|')
    .map((item) => item.trim())
    .filter((item) => item && item !== '/');
}

function mapProductRow(row) {
  const minPrice = Number(row.min_price ?? 0);
  const maxImport = Number(row.max_import_price ?? minPrice);
  const originalPrice = maxImport > minPrice ? maxImport : minPrice;

  const specifications = {};
  if (row.screen_size) specifications.Display = `${row.screen_size}"`;
  if (row.screen_tech) specifications['Screen tech'] = row.screen_tech;
  if (row.chipset) specifications.Chipset = row.chipset;
  if (row.battery) specifications.Battery = row.battery;
  if (row.rear_camera) specifications['Rear camera'] = row.rear_camera;
  if (row.front_camera) specifications['Front camera'] = row.front_camera;
  if (row.operating_system_name) specifications.OS = row.operating_system_name;
  if (row.warranty_period) specifications.Warranty = `${row.warranty_period} months`;

  return {
    id: String(row.product_id),
    name: row.product_name,
    brand: row.brand_name ?? 'Unknown',
    price: minPrice,
    originalPrice,
    imageUrl: row.picture ?? '',
    galleryImages: row.picture ? [row.picture] : [],
    rating: Number(row.avg_rating ?? 0),
    reviewCount: Number(row.review_count ?? 0),
    ramRomOptions: splitPipe(row.ram_rom_options),
    colors: splitPipe(row.color_names),
    specifications,
    isNew: row.status === 1,
  };
}

// GET /products — danh sách sản phẩm cho tab Shop
app.get('/products', async (_req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT
        p.product_id,
        p.product_name,
        p.picture,
        p.status,
        p.battery,
        p.rear_camera,
        p.front_camera,
        p.screen_size,
        p.screen_tech,
        p.chipset,
        p.warranty_period,
        b.brand_name,
        os.operating_system_name,
        MIN(pv.export_price) AS min_price,
        MAX(pv.import_price) AS max_import_price,
        GROUP_CONCAT(
          DISTINCT CONCAT(COALESCE(r.ram_size, ''), '/', COALESCE(ro.rom_size, ''))
          SEPARATOR '|'
        ) AS ram_rom_options,
        GROUP_CONCAT(DISTINCT c.color_name SEPARATOR '|') AS color_names,
        COALESCE(AVG(f.rate), 0) AS avg_rating,
        COUNT(DISTINCT f.feedback_id) AS review_count
      FROM products p
      LEFT JOIN brands b ON p.brand_id = b.brand_id
      LEFT JOIN operating_systems os ON p.operating_system_id = os.operating_system_id
      LEFT JOIN product_versions pv ON p.product_id = pv.product_id AND pv.status = 1
      LEFT JOIN rams r ON pv.ram_id = r.ram_id
      LEFT JOIN roms ro ON pv.rom_id = ro.rom_id
      LEFT JOIN colors c ON pv.color_id = c.color_id
      LEFT JOIN feedbacks f ON f.product_id = p.product_id
      WHERE p.status = 1
      GROUP BY
        p.product_id,
        p.product_name,
        p.picture,
        p.status,
        p.battery,
        p.rear_camera,
        p.front_camera,
        p.screen_size,
        p.screen_tech,
        p.chipset,
        p.warranty_period,
        b.brand_name,
        os.operating_system_name
      ORDER BY p.product_id DESC
    `);

    res.json(rows.map(mapProductRow));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'PRODUCTS_LIST_ERROR' });
  }
});

// --- BẮT ĐẦU FIREBASE ADMIN VÀ OTP CACHE ---
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');
try {
  admin.initializeApp({ credential: admin.cert(serviceAccount) });
  console.log("Firebase Admin initialized successfully.");
} catch(e) {
  console.error("Firebase Admin init error:", e.message);
}
const { getAuth } = require('firebase-admin/auth');
const otpCache = new Map();
// --- KẾT THÚC KHỞI TẠO ---

// POST /auth/sync — Xác thực Google Token, kiểm tra tài khoản
app.post('/auth/sync', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) return res.status(401).json({ message: 'Missing token' });
    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const firebaseUid = decodedToken.uid;
    const email = decodedToken.email || '';
    let name = decodedToken.name || email.split('@')[0];

    const [existing] = await pool.query('SELECT * FROM customers WHERE firebase_uid = ?', [firebaseUid]);
    if (existing.length > 0) {
      const user = existing[0];
      return res.json({ id: String(user.customer_id), name: user.full_name || name, email: user.email || email, phone: user.phone_number || '', avatarUrl: decodedToken.picture || '', gender: user.gender, dob: user.birth_date ? new Date(user.birth_date.getTime() - user.birth_date.getTimezoneOffset() * 60000).toISOString().split('T')[0] : null, address: user.address });
    } else {
      return res.status(404).json({ message: 'Vui lòng nhập số điện thoại để hoàn tất', code: 'REQUIRE_PHONE_LINK' });
    }
  } catch(e) { res.status(401).json({ message: e.message }); }
});

// POST /auth/request-otp — Sinh OTP và gửi qua Cloud Gateway
app.post('/auth/request-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({message: 'Missing phone'});
  
  const generatedOtp = Math.floor(100000 + Math.random() * 900000).toString();
  otpCache.set(phone, { otp: generatedOtp, expires: Date.now() + 5 * 60 * 1000 });
  
  try {
    const gatewayUrl = 'https://api.sms-gate.app/3rdparty/v1/messages';
    const authHeader = 'Basic ' + Buffer.from('6S00HR:euqmhd2yd1fbgn').toString('base64');
    const response = await fetch(gatewayUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': authHeader },
      body: JSON.stringify({
        textMessage: { text: `Ma xac thuc PhoneShop cua ban la: ${generatedOtp}` },
        phoneNumbers: [phone.startsWith('0') ? '+84' + phone.substring(1) : phone]
      }),
      signal: AbortSignal.timeout(8000)
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
app.post('/auth/verify-otp', async (req, res) => {
  const { phone, otp } = req.body;
  const cached = otpCache.get(phone);
  if (!cached || cached.otp !== otp || cached.expires < Date.now()) return res.status(400).json({message: 'Mã OTP không hợp lệ hoặc đã hết hạn.', code: 'INVALID_OTP'});
  
  const [customers] = await pool.query('SELECT * FROM customers WHERE phone_number = ?', [phone]);
  let customer_id;
  let name = `User ${phone.slice(-4)}`;
  
  if (customers.length > 0) {
    customer_id = customers[0].customer_id;
    name = customers[0].full_name || name;
  } else {
    const [result] = await pool.query('INSERT INTO customers (full_name, phone_number, create_at, update_at) VALUES (?, ?, NOW(), NOW())', [name, phone]);
    customer_id = result.insertId;
  }
  otpCache.delete(phone);
  const [finalUser] = await pool.query('SELECT * FROM customers WHERE customer_id = ?', [customer_id]);
  const user = finalUser[0];
  res.json({ id: String(customer_id), name: user.full_name, phone: user.phone_number, email: user.email || '', gender: user.gender, dob: user.birth_date ? new Date(user.birth_date.getTime() - user.birth_date.getTimezoneOffset() * 60000).toISOString().split('T')[0] : null, address: user.address });
});

// POST /auth/link-phone — Cập nhật SĐT vào Google ID và xử lý Merge
app.post('/auth/link-phone', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) return res.status(401).json({message: 'Missing token'});
    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const firebaseUid = decodedToken.uid;
    const email = decodedToken.email || '';
    
    const { phone, otp, force } = req.body;
    const cached = otpCache.get(phone);
    if (!cached || cached.otp !== otp || cached.expires < Date.now()) return res.status(400).json({message: 'OTP Invalid', code: 'INVALID_OTP'});
    
    const [existing] = await pool.query('SELECT * FROM customers WHERE firebase_uid = ?', [firebaseUid]);
    let customer_id;
    let name = decodedToken.name || email.split('@')[0];
    
    if (existing.length > 0) {
      await pool.query('UPDATE customers SET phone_number = ?, full_name = ? WHERE firebase_uid = ?', [phone, name, firebaseUid]);
      customer_id = existing[0].customer_id;
    } else {
      const [phoneExists] = await pool.query('SELECT * FROM customers WHERE phone_number = ?', [phone]);
      const [emailExists] = await pool.query('SELECT * FROM customers WHERE email = ?', [email]);
      
      if (phoneExists.length > 0 && emailExists.length > 0 && phoneExists[0].customer_id !== emailExists[0].customer_id) {
         if (force === true) {
            // Tháo email, firebase_uid khỏi tài khoản cũ (emailExists)
            await pool.query('UPDATE customers SET email = NULL, firebase_uid = NULL WHERE customer_id = ?', [emailExists[0].customer_id]);
            // Cập nhật vào tài khoản SĐT (phoneExists)
            await pool.query('UPDATE customers SET firebase_uid = ?, email = ?, full_name = ? WHERE customer_id = ?', [firebaseUid, email, name, phoneExists[0].customer_id]);
            customer_id = phoneExists[0].customer_id;
         } else {
            return res.status(400).json({ message: 'Số điện thoại này đã liên kết với tài khoản khác. Bạn có muốn thay thế bằng tài khoản hiện tại không?', code: 'PHONE_CONFLICT' });
         }
      } else if (emailExists.length > 0) {
         await pool.query('UPDATE customers SET firebase_uid = ?, phone_number = ?, full_name = ? WHERE customer_id = ?', [firebaseUid, phone, name, emailExists[0].customer_id]);
         customer_id = emailExists[0].customer_id;
      } else if (phoneExists.length > 0) {
         await pool.query('UPDATE customers SET firebase_uid = ?, email = ?, full_name = ? WHERE customer_id = ?', [firebaseUid, email, name, phoneExists[0].customer_id]);
         customer_id = phoneExists[0].customer_id;
      } else {
         const [result] = await pool.query('INSERT INTO customers (firebase_uid, full_name, email, phone_number, create_at, update_at) VALUES (?, ?, ?, ?, NOW(), NOW())', [firebaseUid, name, email, phone]);
         customer_id = result.insertId;
      }
    }
    otpCache.delete(phone);
    const [finalUser] = await pool.query('SELECT * FROM customers WHERE customer_id = ?', [customer_id]);
    const user = finalUser[0];
    res.json({ id: String(customer_id), name: user.full_name, email: user.email, phone: user.phone_number, gender: user.gender, dob: user.birth_date ? new Date(user.birth_date.getTime() - user.birth_date.getTimezoneOffset() * 60000).toISOString().split('T')[0] : null, address: user.address, avatarUrl: decodedToken.picture || '' });
  } catch(e) { res.status(500).json({ message: e.message, code: 'LINK_PHONE_ERROR' }); }
});

// PUT /profile — Cập nhật thông tin user
app.put('/profile', async (req, res) => {
  try {
    const { customerId, name, gender, dob, address } = req.body;
    if (!customerId) return res.status(400).json({ message: 'Missing customerId' });
    let genderVal = null;
    if (gender === 'Male') genderVal = 1;
    else if (gender === 'Female') genderVal = 2;
    else if (gender === 'Other') genderVal = 3;
    
    await pool.query('UPDATE customers SET full_name = ?, gender = ?, birth_date = ?, address = ? WHERE customer_id = ?', [name, genderVal, dob || null, address || null, customerId]);
    const [rows] = await pool.query('SELECT * FROM customers WHERE customer_id = ?', [customerId]);
    const user = rows[0];
    res.json({ id: String(user.customer_id), name: user.full_name, email: user.email, phone: user.phone_number, gender: user.gender, dob: user.birth_date ? new Date(user.birth_date.getTime() - user.birth_date.getTimezoneOffset() * 60000).toISOString().split('T')[0] : null, address: user.address });
  } catch(e) { res.status(500).json({ message: e.message }); }
});

app.get('/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ ok: false, message: err.message });
  }
});

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  console.log(`PhoneShop API listening on http://localhost:${port}`);
});
