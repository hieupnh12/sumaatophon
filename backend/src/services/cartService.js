const pool = require('../../db');

async function getOrCreateActiveCart(customerId) {
  const [rows] = await pool.query(
    'SELECT cart_id FROM carts WHERE customer_id = ? AND status = 1 ORDER BY cart_id DESC LIMIT 1',
    [customerId],
  );
  if (rows.length > 0) return rows[0].cart_id;

  const [result] = await pool.query(
    'INSERT INTO carts (customer_id, status) VALUES (?, 1)',
    [customerId],
  );
  return result.insertId;
}

async function fetchVersionStock(productVersionId, conn = pool) {
  const [rows] = await conn.query(
    `
      SELECT COUNT(*) AS stock_quantity
      FROM product_items
      WHERE product_version_id = ?
        AND status = 'IN_STOCK'
        AND order_detail_id IS NULL
    `,
    [productVersionId],
  );
  return Number(rows[0]?.stock_quantity ?? 0);
}

async function fetchCartItemsEnriched(cartId) {
  const [rows] = await pool.query(
    `
      SELECT
        ci.cart_item_id,
        ci.product_version_id,
        ci.quantity,
        pv.product_id,
        pv.export_price,
        pv.import_price,
        pv.picture AS version_picture,
        p.product_name,
        p.picture AS product_picture,
        p.status AS product_status,
        b.brand_name,
        COALESCE(AVG(f.rate), 0) AS avg_rating,
        COUNT(DISTINCT f.feedback_id) AS review_count,
        r.ram_size,
        ro.rom_size,
        c.color_name,
        COUNT(DISTINCT CASE
          WHEN pi.status = 'IN_STOCK' AND pi.order_detail_id IS NULL THEN pi.imei
        END) AS stock_quantity
      FROM cart_items ci
      INNER JOIN product_versions pv ON ci.product_version_id = pv.product_version_id
      INNER JOIN products p ON pv.product_id = p.product_id
      LEFT JOIN brands b ON p.brand_id = b.brand_id
      LEFT JOIN rams r ON pv.ram_id = r.ram_id
      LEFT JOIN roms ro ON pv.rom_id = ro.rom_id
      LEFT JOIN colors c ON pv.color_id = c.color_id
      LEFT JOIN feedbacks f ON f.product_id = p.product_id
      LEFT JOIN product_items pi ON pi.product_version_id = pv.product_version_id
      WHERE ci.cart_id = ? AND ci.status = 1
      GROUP BY
        ci.cart_item_id,
        ci.product_version_id,
        ci.quantity,
        pv.product_id,
        pv.export_price,
        pv.import_price,
        pv.picture,
        p.product_name,
        p.picture,
        p.status,
        b.brand_name,
        r.ram_size,
        ro.rom_size,
        c.color_name
      ORDER BY ci.cart_item_id DESC
    `,
    [cartId],
  );

  return rows.map((row) => {
    const exportPrice = Number(row.export_price ?? 0);
    const importPrice = Number(row.import_price ?? exportPrice);
    const originalPrice = importPrice > exportPrice ? importPrice : exportPrice;
    const versionPicture = row.version_picture ? String(row.version_picture).trim() : '';
    const productPicture = row.product_picture ? String(row.product_picture).trim() : '';

    return {
      cartItemId: String(row.cart_item_id),
      productVersionId: String(row.product_version_id),
      productId: String(row.product_id),
      productName: row.product_name,
      productBrand: row.brand_name ?? 'Unknown',
      productPrice: exportPrice,
      productOriginalPrice: originalPrice,
      productImageUrl: versionPicture || productPicture,
      productRating: Number(row.avg_rating ?? 0),
      productReviewCount: Number(row.review_count ?? 0),
      productIsNew: row.product_status === 1,
      versionColor: row.color_name ? String(row.color_name).trim() : '',
      versionRam: row.ram_size ? String(row.ram_size).trim() : '',
      versionRom: row.rom_size ? String(row.rom_size).trim() : '',
      versionPrice: exportPrice,
      versionStockQuantity: Number(row.stock_quantity ?? 0),
      versionImageUrl: versionPicture || productPicture,
      quantity: Number(row.quantity ?? 1),
    };
  });
}

async function clearCustomerCart(customerId, conn = pool) {
  const [carts] = await conn.query(
    'SELECT cart_id FROM carts WHERE customer_id = ? AND status = 1',
    [customerId],
  );
  for (const cart of carts) {
    await conn.query('DELETE FROM cart_items WHERE cart_id = ?', [cart.cart_id]);
  }
}

module.exports = {
  getOrCreateActiveCart,
  fetchVersionStock,
  fetchCartItemsEnriched,
  clearCustomerCart,
};
