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
