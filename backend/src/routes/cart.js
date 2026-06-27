const express = require('express');
const pool = require('../../db');
const {
  getOrCreateActiveCart,
  fetchVersionStock,
  fetchCartItemsEnriched,
  clearCustomerCart,
} = require('../services/cartService');

const router = express.Router();

// GET /api/cart?customerId=...
router.get('/api/cart', async (req, res) => {
  try {
    const { customerId } = req.query;
    if (!customerId) {
      return res.status(400).json({ message: 'Missing customerId', code: 'MISSING_CUSTOMER_ID' });
    }

    const [carts] = await pool.query(
      'SELECT cart_id FROM carts WHERE customer_id = ? AND status = 1 ORDER BY cart_id DESC LIMIT 1',
      [customerId],
    );
    if (carts.length === 0) {
      return res.json([]);
    }

    const items = await fetchCartItemsEnriched(carts[0].cart_id);
    res.json(items);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'CART_GET_ERROR' });
  }
});

// POST /api/cart/items — thêm hoặc tăng quantity theo product_version_id
router.post('/api/cart/items', async (req, res) => {
  try {
    const { customerId, productVersionId } = req.body;
    if (!customerId || !productVersionId) {
      return res.status(400).json({ message: 'Missing customerId or productVersionId', code: 'MISSING_FIELDS' });
    }

    const stock = await fetchVersionStock(productVersionId);
    if (stock <= 0) {
      return res.status(400).json({ message: 'Out of stock', code: 'OUT_OF_STOCK' });
    }

    const cartId = await getOrCreateActiveCart(customerId);
    const [existing] = await pool.query(
      'SELECT cart_item_id, quantity FROM cart_items WHERE cart_id = ? AND product_version_id = ? AND status = 1',
      [cartId, productVersionId],
    );

    if (existing.length > 0) {
      const currentQty = Number(existing[0].quantity ?? 1);
      if (currentQty >= stock) {
        return res.status(400).json({ message: 'Maximum stock reached', code: 'MAX_STOCK' });
      }
      await pool.query('UPDATE cart_items SET quantity = ? WHERE cart_item_id = ?', [
        currentQty + 1,
        existing[0].cart_item_id,
      ]);
    } else {
      await pool.query(
        'INSERT INTO cart_items (cart_id, product_version_id, quantity, status) VALUES (?, ?, 1, 1)',
        [cartId, productVersionId],
      );
    }

    await pool.query('UPDATE carts SET update_date = NOW() WHERE cart_id = ?', [cartId]);
    const items = await fetchCartItemsEnriched(cartId);
    res.json(items);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'CART_ADD_ERROR' });
  }
});

// PUT /api/cart/items/:productVersionId
router.put('/api/cart/items/:productVersionId', async (req, res) => {
  try {
    const { productVersionId } = req.params;
    const { customerId, quantity } = req.body;
    if (!customerId || !productVersionId || quantity == null) {
      return res.status(400).json({ message: 'Missing fields', code: 'MISSING_FIELDS' });
    }

    const qty = Number(quantity);
    if (qty < 1) {
      return res.status(400).json({ message: 'Quantity must be at least 1', code: 'INVALID_QUANTITY' });
    }

    const stock = await fetchVersionStock(productVersionId);
    if (qty > stock) {
      return res.status(400).json({ message: 'Maximum stock reached', code: 'MAX_STOCK' });
    }

    const cartId = await getOrCreateActiveCart(customerId);
    const [existing] = await pool.query(
      'SELECT cart_item_id FROM cart_items WHERE cart_id = ? AND product_version_id = ? AND status = 1',
      [cartId, productVersionId],
    );
    if (existing.length === 0) {
      return res.status(404).json({ message: 'Cart item not found', code: 'CART_ITEM_NOT_FOUND' });
    }

    await pool.query('UPDATE cart_items SET quantity = ? WHERE cart_item_id = ?', [
      qty,
      existing[0].cart_item_id,
    ]);
    await pool.query('UPDATE carts SET update_date = NOW() WHERE cart_id = ?', [cartId]);

    const items = await fetchCartItemsEnriched(cartId);
    res.json(items);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'CART_UPDATE_ERROR' });
  }
});

// DELETE /api/cart/items/:productVersionId?customerId=...
router.delete('/api/cart/items/:productVersionId', async (req, res) => {
  try {
    const { productVersionId } = req.params;
    const { customerId } = req.query;
    if (!customerId || !productVersionId) {
      return res.status(400).json({ message: 'Missing fields', code: 'MISSING_FIELDS' });
    }

    const [carts] = await pool.query(
      'SELECT cart_id FROM carts WHERE customer_id = ? AND status = 1 ORDER BY cart_id DESC LIMIT 1',
      [customerId],
    );
    if (carts.length === 0) {
      return res.json([]);
    }

    const cartId = carts[0].cart_id;
    await pool.query('DELETE FROM cart_items WHERE cart_id = ? AND product_version_id = ?', [
      cartId,
      productVersionId,
    ]);
    await pool.query('UPDATE carts SET update_date = NOW() WHERE cart_id = ?', [cartId]);

    const items = await fetchCartItemsEnriched(cartId);
    res.json(items);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'CART_REMOVE_ERROR' });
  }
});

// DELETE /api/cart?customerId=...
router.delete('/api/cart', async (req, res) => {
  try {
    const { customerId } = req.query;
    if (!customerId) {
      return res.status(400).json({ message: 'Missing customerId', code: 'MISSING_CUSTOMER_ID' });
    }

    await clearCustomerCart(customerId);
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message, code: 'CART_CLEAR_ERROR' });
  }
});

module.exports = router;
