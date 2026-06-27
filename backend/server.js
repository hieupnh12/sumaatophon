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

function mergeUniqueImages(mainImage, extraImages = []) {
  const images = [];
  const add = (url) => {
    const trimmed = String(url ?? '').trim();
    if (trimmed && !images.includes(trimmed)) images.push(trimmed);
  };

  add(mainImage);
  const extras = Array.isArray(extraImages) ? extraImages : [];
  for (const image of extras) add(image);
  return images;
}

function mapProductRow(row, galleryImages = null) {
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

  const images = mergeUniqueImages(row.picture, galleryImages);

  return {
    id: String(row.product_id),
    name: row.product_name,
    brand: row.brand_name ?? 'Unknown',
    price: minPrice,
    originalPrice,
    imageUrl: images[0] ?? '',
    galleryImages: images,
    rating: Number(row.avg_rating ?? 0),
    reviewCount: Number(row.review_count ?? 0),
    ramRomOptions: splitPipe(row.ram_rom_options),
    colors: splitPipe(row.color_names),
    specifications,
    isNew: row.status === 1,
    stockQuantity: Number(row.stock_quantity ?? 0),
    versions: [],
    feedbacks: [],
  };
}

function mapProductVersionRow(row, versionImages = []) {
  const ram = row.ram_size ? String(row.ram_size).trim() : '';
  const rom = row.rom_size ? String(row.rom_size).trim() : '';
  const ramRom = [ram, rom].filter(Boolean).join('/');

  return {
    id: String(row.product_version_id),
    color: row.color_name ? String(row.color_name).trim() : '',
    ram,
    rom,
    ramRom,
    price: Number(row.export_price ?? 0),
    stockQuantity: Number(row.stock_quantity ?? 0),
    imageUrl: versionImages[0] ?? '',
    galleryImages: versionImages,
  };
}

function mapFeedbackRow(row) {
  return {
    id: String(row.feedback_id),
    customerName: row.full_name || 'Customer',
    rate: Number(row.rate ?? 0),
    content: row.content || '',
    createdAt: row.date ? new Date(row.date).toISOString() : null,
  };
}

async function fetchProductGalleryImages(productId) {
  const [rows] = await pool.query(
    `
      SELECT vi.image
      FROM version_image vi
      INNER JOIN product_versions pv ON vi.product_version_id = pv.product_version_id
      WHERE pv.product_id = ? AND vi.image IS NOT NULL AND vi.image != ''
      ORDER BY vi.image_id
    `,
    [productId],
  );

  return rows.map((row) => row.image).filter(Boolean);
}

async function fetchProductFeedbacks(productId) {
  const [rows] = await pool.query(
    `
      SELECT
        f.feedback_id,
        f.rate,
        f.content,
        f.date,
        c.full_name
      FROM feedbacks f
      LEFT JOIN customers c ON f.customer_id = c.customer_id
      WHERE f.product_id = ? AND (f.status = 1 OR f.status IS NULL)
      ORDER BY f.date DESC
    `,
    [productId],
  );

  return rows.map(mapFeedbackRow);
}

async function fetchProductVersions(productId) {
  const [rows] = await pool.query(
    `
      SELECT
        pv.product_version_id,
        pv.export_price,
        r.ram_size,
        ro.rom_size,
        c.color_name,
        COUNT(DISTINCT CASE
          WHEN pi.status = 'IN_STOCK' AND pi.order_detail_id IS NULL THEN pi.imei
        END) AS stock_quantity
      FROM product_versions pv
      LEFT JOIN rams r ON pv.ram_id = r.ram_id
      LEFT JOIN roms ro ON pv.rom_id = ro.rom_id
      LEFT JOIN colors c ON pv.color_id = c.color_id
      LEFT JOIN product_items pi ON pi.product_version_id = pv.product_version_id
      WHERE pv.product_id = ? AND pv.status = 1
      GROUP BY
        pv.product_version_id,
        pv.export_price,
        r.ram_size,
        ro.rom_size,
        c.color_name
      ORDER BY stock_quantity DESC, pv.product_version_id
    `,
    [productId],
  );

  const [imageRows] = await pool.query(
    `
      SELECT vi.product_version_id, vi.image
      FROM version_image vi
      INNER JOIN product_versions pv ON vi.product_version_id = pv.product_version_id
      WHERE pv.product_id = ?
        AND vi.image IS NOT NULL AND vi.image != ''
      ORDER BY vi.product_version_id, vi.image_id
    `,
    [productId],
  );

  const imagesByVersion = new Map();
  for (const row of imageRows) {
    const versionId = String(row.product_version_id);
    if (!imagesByVersion.has(versionId)) {
      imagesByVersion.set(versionId, []);
    }
    imagesByVersion.get(versionId).push(String(row.image).trim());
  }

  return rows.map((row) => {
    const versionId = String(row.product_version_id);
    return mapProductVersionRow(row, imagesByVersion.get(versionId) ?? []);
  });
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
        COUNT(DISTINCT f.feedback_id) AS review_count,
        COUNT(DISTINCT CASE
          WHEN pi.status = 'IN_STOCK' AND pi.order_detail_id IS NULL THEN pi.imei
        END) AS stock_quantity
      FROM products p
      LEFT JOIN brands b ON p.brand_id = b.brand_id
      LEFT JOIN operating_systems os ON p.operating_system_id = os.operating_system_id
      LEFT JOIN product_versions pv ON p.product_id = pv.product_id AND pv.status = 1
      LEFT JOIN rams r ON pv.ram_id = r.ram_id
      LEFT JOIN roms ro ON pv.rom_id = ro.rom_id
      LEFT JOIN colors c ON pv.color_id = c.color_id
      LEFT JOIN feedbacks f ON f.product_id = p.product_id
      LEFT JOIN product_items pi ON pi.product_version_id = pv.product_version_id
      WHERE p.stock_quantity > 0
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
        HAVING COUNT(DISTINCT CASE
        WHEN pi.status = 'IN_STOCK' AND pi.order_detail_id IS NULL THEN pi.imei
      END) > 0
      ORDER BY p.product_id DESC
    `);

    res.json(rows.map((row) => mapProductRow(row)));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'PRODUCTS_LIST_ERROR' });
  }
});

// GET /products/:id/feedbacks — danh sách đánh giá của sản phẩm
app.get('/products/:id/feedbacks', async (req, res) => {
  try {
    const productId = req.params.id;
    if (!productId) {
      return res.status(400).json({ message: 'Product ID is required', code: 'MISSING_PRODUCT_ID' });
    }

    const feedbacks = await fetchProductFeedbacks(productId);
    res.json(feedbacks);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'PRODUCT_FEEDBACKS_ERROR' });
  }
});

// GET /products/:id — chi tiết sản phẩm
app.get('/products/:id', async (req, res) => {
  try {
     const productId = req.params.id;

    if (!productId) {
      return res.status(400).json({ message: 'Product ID is required', code: 'MISSING_PRODUCT_ID' });
    }


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
        COUNT(DISTINCT f.feedback_id) AS review_count,
        COUNT(DISTINCT CASE
          WHEN pi.status = 'IN_STOCK' AND pi.order_detail_id IS NULL THEN pi.imei
        END) AS stock_quantity,
        GROUP_CONCAT(DISTINCT CASE
          WHEN pi.status = 'IN_STOCK' AND pi.order_detail_id IS NULL THEN pi.imei
        END SEPARATOR ',') AS imei_list
      FROM products p
      LEFT JOIN brands b ON p.brand_id = b.brand_id
      LEFT JOIN operating_systems os ON p.operating_system_id = os.operating_system_id
      LEFT JOIN product_versions pv ON p.product_id = pv.product_id AND pv.status = 1
      LEFT JOIN rams r ON pv.ram_id = r.ram_id
      LEFT JOIN roms ro ON pv.rom_id = ro.rom_id
      LEFT JOIN colors c ON pv.color_id = c.color_id
      LEFT JOIN feedbacks f ON f.product_id = p.product_id
      LEFT JOIN product_items pi ON pi.product_version_id = pv.product_version_id
      WHERE p.status = 1 AND p.product_id = ?
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
        
    `, [productId]); // [productId] là tham số để truyền vào query
    
    if(rows.length === 0) {
      return res.status(404).json({ message: 'Product not found', code: 'PRODUCT_NOT_FOUND' });
    }

    const galleryImages = await fetchProductGalleryImages(productId);
    const product = mapProductRow(rows[0], galleryImages);
    product.versions = await fetchProductVersions(productId);
    product.feedbacks = await fetchProductFeedbacks(productId);
    res.json(product);
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
  console.log(`[Verify OTP] Received phone: ${phone}, otp: ${otp}`);
  const cached = otpCache.get(phone);
  if (!cached || cached.otp !== otp || cached.expires < Date.now()) {
    console.log(`[Verify OTP] Failed! Cached:`, cached);
    return res.status(400).json({message: 'Mã OTP không hợp lệ hoặc đã hết hạn.', code: 'INVALID_OTP'});
  }
  
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

// --- ADDRESS BOOK ---
// GET /api/addresses?customerId=...
app.get('/api/addresses', async (req, res) => {
  try {
    const { customerId } = req.query;
    if (!customerId) return res.status(400).json({ message: 'Missing customerId' });
    const [rows] = await pool.query('SELECT * FROM customer_address_book WHERE customer_id = ? ORDER BY is_default DESC, address_book_id DESC', [customerId]);
    res.json(rows.map(row => ({
      id: String(row.address_book_id),
      province: row.province,
      ward: row.ward,
      street: row.street,
      type: row.type,
      isDefault: row.is_default === 1,
      receiverName: row.receiver_name,
      receiverPhone: row.receiver_phone
    })));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/addresses
app.post('/api/addresses', async (req, res) => {
  try {
    const { customerId, province, ward, street, type, isDefault, receiverName, receiverPhone } = req.body;
    if (!customerId || !province || !ward || !street) return res.status(400).json({ message: 'Missing required fields' });
    
    if (isDefault) {
      await pool.query('UPDATE customer_address_book SET is_default = 0 WHERE customer_id = ?', [customerId]);
    }

    const [result] = await pool.query(
      'INSERT INTO customer_address_book (customer_id, province, ward, street, type, is_default, receiver_name, receiver_phone) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [customerId, province, ward, street, type || 'home', isDefault ? 1 : 0, receiverName, receiverPhone]
    );

    res.json({
      id: String(result.insertId),
      province, ward, street, type: type || 'home', isDefault: !!isDefault, receiverName, receiverPhone
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/addresses/:id
app.put('/api/addresses/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { customerId, province, ward, street, type, isDefault, receiverName, receiverPhone } = req.body;
    
    if (isDefault) {
      await pool.query('UPDATE customer_address_book SET is_default = 0 WHERE customer_id = ?', [customerId]);
    }

    await pool.query(
      'UPDATE customer_address_book SET province = ?, ward = ?, street = ?, type = ?, is_default = ?, receiver_name = ?, receiver_phone = ? WHERE address_book_id = ? AND customer_id = ?',
      [province, ward, street, type, isDefault ? 1 : 0, receiverName, receiverPhone, id, customerId]
    );
    
    res.json({ id, province, ward, street, type, isDefault: !!isDefault, receiverName, receiverPhone });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/addresses/:id
app.delete('/api/addresses/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { customerId } = req.query; // pass as query param
    await pool.query('DELETE FROM customer_address_book WHERE address_book_id = ? AND customer_id = ?', [id, customerId]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/addresses/:id/default
app.put('/api/addresses/:id/default', async (req, res) => {
  try {
    const { id } = req.params;
    const { customerId } = req.body;
    await pool.query('UPDATE customer_address_book SET is_default = 0 WHERE customer_id = ?', [customerId]);
    await pool.query('UPDATE customer_address_book SET is_default = 1 WHERE address_book_id = ? AND customer_id = ?', [id, customerId]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- ORDERS ---
app.use('/api/orders', require('./orders/orders.routes'));

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
