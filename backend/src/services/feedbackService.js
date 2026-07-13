const pool = require('../../db');
const { mapFeedbackRow } = require('../utils/productMappers');

async function customerPurchasedProduct(pool, customerId, productId) {
  const [rows] = await pool.query(
    `
      SELECT 1
      FROM order_details od
      INNER JOIN orders o ON o.order_id = od.order_id
      INNER JOIN product_versions pv ON pv.product_version_id = od.product_version_id
      WHERE o.customer_id = ?
        AND pv.product_id = ?
        AND o.status IN ('DELIVERED', 'COMPLETED')
      LIMIT 1
    `,
    [customerId, productId],
  );
  return rows.length > 0;
}

async function customerHasReviewed(pool, customerId, productId) {
  const [rows] = await pool.query(
    `
      SELECT feedback_id
      FROM feedbacks
      WHERE customer_id = ?
        AND product_id = ?
        AND (status = 1 OR status IS NULL)
      LIMIT 1
    `,
    [customerId, productId],
  );
  return rows.length > 0;
}

async function getFeedbackStatus(customerId, productId) {
  const purchased = await customerPurchasedProduct(pool, customerId, productId);
  const hasReviewed = purchased
    ? await customerHasReviewed(pool, customerId, productId)
    : false;

  return {
    canReview: purchased && !hasReviewed,
    hasReviewed,
  };
}

async function createProductFeedback({ customerId, productId, rate, content }) {
  const numericCustomerId = Number(customerId);
  const numericProductId = Number(productId);
  const numericRate = Number(rate);
  const trimmedContent = String(content ?? '').trim();

  if (!Number.isFinite(numericCustomerId) || numericCustomerId <= 0) {
    const error = new Error('Invalid customerId');
    error.code = 'FEEDBACK_INVALID_CUSTOMER';
    throw error;
  }
  if (!Number.isFinite(numericProductId) || numericProductId <= 0) {
    const error = new Error('Invalid productId');
    error.code = 'FEEDBACK_INVALID_PRODUCT';
    throw error;
  }
  if (!Number.isFinite(numericRate) || numericRate < 1 || numericRate > 5) {
    const error = new Error('Rate must be between 1 and 5');
    error.code = 'FEEDBACK_INVALID_RATE';
    throw error;
  }
  if (trimmedContent.length < 3) {
    const error = new Error('Review content is too short');
    error.code = 'FEEDBACK_INVALID_CONTENT';
    throw error;
  }

  const purchased = await customerPurchasedProduct(pool, numericCustomerId, numericProductId);
  if (!purchased) {
    const error = new Error('You can only review products from completed orders');
    error.code = 'FEEDBACK_NOT_ELIGIBLE';
    throw error;
  }

  const alreadyReviewed = await customerHasReviewed(pool, numericCustomerId, numericProductId);
  if (alreadyReviewed) {
    const error = new Error('You already reviewed this product');
    error.code = 'FEEDBACK_ALREADY_EXISTS';
    throw error;
  }

  const [result] = await pool.query(
    `
      INSERT INTO feedbacks (customer_id, product_id, rate, content, status, date)
      VALUES (?, ?, ?, ?, 1, NOW())
    `,
    [numericCustomerId, numericProductId, Math.round(numericRate), trimmedContent],
  );

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
      WHERE f.feedback_id = ?
    `,
    [result.insertId],
  );

  return mapFeedbackRow(rows[0]);
}

module.exports = {
  getFeedbackStatus,
  createProductFeedback,
};
