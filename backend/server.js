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
    stockQuantity: Number(row.stock_quantity ?? 0),
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




// GET /products — danh sách sản phẩm cho tab Shop , voiws req = request , res = response
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

    res.json(mapProductRow(rows[0]));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'PRODUCTS_LIST_ERROR' });
  }
});







// POST /auth/google — đăng nhập/đăng ký bằng Google ID token
app.post('/auth/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ message: 'Missing idToken', code: 'MISSING_ID_TOKEN' });
    }

    // Xác thực Google ID Token qua Google API
    const verifyUrl = `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`;
    const response = await fetch(verifyUrl);
    if (!response.ok) {
      const errorText = await response.text();
      return res.status(401).json({ message: 'Invalid Google ID token', code: 'INVALID_ID_TOKEN', details: errorText });
    }

    const payload = await response.json();
    const googleId = payload.sub;
    const email = payload.email;
    const name = payload.name || 'Google User';
    const avatarUrl = payload.picture || '';

    if (!email) {
      return res.status(400).json({ message: 'Google account does not have an email', code: 'NO_EMAIL' });
    }

    // Kiểm tra người dùng đã tồn tại trong MySQL chưa dựa trên email
    const [customers] = await pool.query('SELECT * FROM customers WHERE email = ?', [email]);

    let customer_id;
    if (customers.length > 0) {
      customer_id = customers[0].customer_id;
      // Kiểm tra xem đã liên kết Google chưa
      const [auths] = await pool.query('SELECT * FROM customer_auths WHERE customer_id = ? AND provider = ?', [customer_id, 'google']);
      if (auths.length === 0) {
        await pool.query(
          'INSERT INTO customer_auths (customer_id, provider, provider_user_id) VALUES (?, ?, ?)',
          [customer_id, 'google', googleId]
        );
      } else if (auths[0].provider_user_id !== googleId) {
        await pool.query(
          'UPDATE customer_auths SET provider_user_id = ? WHERE auth_id = ?',
          [googleId, auths[0].auth_id]
        );
      }
    } else {
      // Đăng ký mới customer
      const [result] = await pool.query(
        'INSERT INTO customers (full_name, email, create_at, update_at) VALUES (?, ?, NOW(), NOW())',
        [name, email]
      );
      customer_id = result.insertId;
      // Thêm thông tin liên kết Google
      await pool.query(
        'INSERT INTO customer_auths (customer_id, provider, provider_user_id) VALUES (?, ?, ?)',
        [customer_id, 'google', googleId]
      );
    }

    let user = {
      id: customer_id,
      email: email,
      name: customers.length > 0 ? (customers[0].full_name || name) : name,
      avatar_url: avatarUrl, // Database hiện tại chưa có cột avatar nên tạm thời chỉ trả về cho App hiển thị
    };

    // Trả về theo định dạng khớp UserEntity của Flutter
    res.json({
      id: String(user.id),
      name: user.name,
      email: user.email,
      avatarUrl: user.avatar_url,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'AUTH_GOOGLE_ERROR' });
  }
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
