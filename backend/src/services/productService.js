const pool = require('../../db');
const {
  mapProductVersionRow,
  mapFeedbackRow,
} = require('../utils/productMappers');

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

module.exports = {
  fetchProductGalleryImages,
  fetchProductFeedbacks,
  fetchProductVersions,
};
