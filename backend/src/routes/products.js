const express = require('express');
const pool = require('../../db');
const { mapProductRow } = require('../utils/productMappers');
const {
  fetchProductGalleryImages,
  fetchProductFeedbacks,
  fetchProductVersions,
} = require('../services/productService');
const {
  getFeedbackStatus,
  createProductFeedback,
} = require('../services/feedbackService');

const router = express.Router();

// GET /products — danh sách sản phẩm cho tab Shop
router.get('/products', async (_req, res) => {
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

// GET /products/:id/feedback-status?customerId= — đủ điều kiện đánh giá?
router.get('/products/:id/feedback-status', async (req, res) => {
  try {
    const productId = Number(req.params.id);
    const customerId = Number(req.query.customerId);
    if (!productId || !customerId) {
      return res.status(400).json({
        message: 'productId and customerId are required',
        code: 'FEEDBACK_STATUS_BAD_REQUEST',
      });
    }

    const status = await getFeedbackStatus(customerId, productId);
    res.json(status);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'FEEDBACK_STATUS_ERROR' });
  }
});

// POST /products/:id/feedbacks — gửi đánh giá sau khi nhận hàng
router.post('/products/:id/feedbacks', async (req, res) => {
  try {
    const productId = req.params.id;
    const { customerId, rate, content } = req.body;
    if (!productId || !customerId) {
      return res.status(400).json({
        message: 'productId and customerId are required',
        code: 'FEEDBACK_BAD_REQUEST',
      });
    }

    const feedback = await createProductFeedback({
      customerId,
      productId,
      rate,
      content,
    });
    res.status(201).json(feedback);
  } catch (err) {
    const code = err.code || 'FEEDBACK_CREATE_ERROR';
    const status =
      code === 'FEEDBACK_NOT_ELIGIBLE' || code === 'FEEDBACK_ALREADY_EXISTS' ? 403 : 400;
    res.status(status).json({ message: err.message, code });
  }
});

// GET /products/:id/feedbacks — danh sách đánh giá của sản phẩm
router.get('/products/:id/feedbacks', async (req, res) => {
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
router.get('/products/:id', async (req, res) => {
  try {
    const productId = req.params.id;

    if (!productId) {
      return res.status(400).json({ message: 'Product ID is required', code: 'MISSING_PRODUCT_ID' });
    }

    const [rows] = await pool.query(
      `
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
    `,
      [productId],
    );

    if (rows.length === 0) {
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

module.exports = router;
