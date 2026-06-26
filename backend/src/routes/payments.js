const express = require('express');

const router = express.Router();

// POST /api/payments/payos/create — tạo link thanh toán PayOS (stub: cấu hình PAYOS_* trong .env sau)
router.post('/api/payments/payos/create', async (req, res) => {
  try {
    const { orderId, amount, description } = req.body;
    if (!orderId || !amount) {
      return res.status(400).json({ message: 'Missing orderId or amount' });
    }

    // TODO: tích hợp PayOS SDK thật khi có PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY
    const checkoutUrl = `https://pay.payos.vn/web/${orderId}`;

    res.json({
      checkoutUrl,
      qrCode: null,
      paymentLinkId: String(orderId),
      description: description || '',
      amount: Number(amount),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
