const express = require('express');
const pool = require('../../db');

const router = express.Router();

// GET /api/addresses?customerId=...
router.get('/api/addresses', async (req, res) => {
  try {
    const { customerId } = req.query;
    if (!customerId) return res.status(400).json({ message: 'Missing customerId' });
    const [rows] = await pool.query(
      'SELECT * FROM customer_address_book WHERE customer_id = ? ORDER BY is_default DESC, address_book_id DESC',
      [customerId],
    );
    res.json(
      rows.map((row) => ({
        id: String(row.address_book_id),
        province: row.province,
        ward: row.ward,
        street: row.street,
        type: row.type,
        isDefault: row.is_default === 1,
        receiverName: row.receiver_name,
        receiverPhone: row.receiver_phone,
      })),
    );
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/addresses
router.post('/api/addresses', async (req, res) => {
  try {
    const { customerId, province, ward, street, type, isDefault, receiverName, receiverPhone } = req.body;
    if (!customerId || !province || !ward || !street) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    if (isDefault) {
      await pool.query('UPDATE customer_address_book SET is_default = 0 WHERE customer_id = ?', [customerId]);
    }

    const [result] = await pool.query(
      'INSERT INTO customer_address_book (customer_id, province, ward, street, type, is_default, receiver_name, receiver_phone) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [customerId, province, ward, street, type || 'home', isDefault ? 1 : 0, receiverName, receiverPhone],
    );

    res.json({
      id: String(result.insertId),
      province,
      ward,
      street,
      type: type || 'home',
      isDefault: !!isDefault,
      receiverName,
      receiverPhone,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/addresses/:id
router.put('/api/addresses/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { customerId, province, ward, street, type, isDefault, receiverName, receiverPhone } = req.body;

    if (isDefault) {
      await pool.query('UPDATE customer_address_book SET is_default = 0 WHERE customer_id = ?', [customerId]);
    }

    await pool.query(
      'UPDATE customer_address_book SET province = ?, ward = ?, street = ?, type = ?, is_default = ?, receiver_name = ?, receiver_phone = ? WHERE address_book_id = ? AND customer_id = ?',
      [province, ward, street, type, isDefault ? 1 : 0, receiverName, receiverPhone, id, customerId],
    );

    res.json({ id, province, ward, street, type, isDefault: !!isDefault, receiverName, receiverPhone });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/addresses/:id
router.delete('/api/addresses/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { customerId } = req.query;
    await pool.query('DELETE FROM customer_address_book WHERE address_book_id = ? AND customer_id = ?', [
      id,
      customerId,
    ]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/addresses/:id/default
router.put('/api/addresses/:id/default', async (req, res) => {
  try {
    const { id } = req.params;
    const { customerId } = req.body;
    await pool.query('UPDATE customer_address_book SET is_default = 0 WHERE customer_id = ?', [customerId]);
    await pool.query(
      'UPDATE customer_address_book SET is_default = 1 WHERE address_book_id = ? AND customer_id = ?',
      [id, customerId],
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
