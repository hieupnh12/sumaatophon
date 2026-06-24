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
  for (const image of extraImages) add(image);
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
      ORDER BY pv.product_version_id
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

    res.json(rows.map(mapProductRow));
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
