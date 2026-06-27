const express = require('express');
const pool = require('../../db');

const router = express.Router();

function formatDob(birthDate) {
  if (!birthDate) return null;
  return new Date(birthDate.getTime() - birthDate.getTimezoneOffset() * 60000)
    .toISOString()
    .split('T')[0];
}

// PUT /profile — Cập nhật thông tin user
router.put('/profile', async (req, res) => {
  try {
    const { customerId, name, gender, dob, address } = req.body;
    if (!customerId) return res.status(400).json({ message: 'Missing customerId' });
    let genderVal = null;
    if (gender === 'Male') genderVal = 1;
    else if (gender === 'Female') genderVal = 2;
    else if (gender === 'Other') genderVal = 3;

    await pool.query(
      'UPDATE customers SET full_name = ?, gender = ?, birth_date = ?, address = ? WHERE customer_id = ?',
      [name, genderVal, dob || null, address || null, customerId],
    );
    const [rows] = await pool.query('SELECT * FROM customers WHERE customer_id = ?', [customerId]);
    const user = rows[0];
    res.json({
      id: String(user.customer_id),
      name: user.full_name,
      email: user.email,
      phone: user.phone_number,
      gender: user.gender,
      dob: formatDob(user.birth_date),
      address: user.address,
    });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;
