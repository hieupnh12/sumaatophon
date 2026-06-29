const pool = require('../../db');

function formatDate(dateString) {
  if (!dateString) return '';
  const date = new Date(dateString);
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = date.getFullYear();
  return `${day}/${month}/${year}`;
}

const getEligibleItems = async (req, res) => {
  try {
    const { customerId } = req.query;
    if (!customerId) {
      return res.status(400).json({ message: 'Missing customerId' });
    }

    // Lấy các sản phẩm từ các đơn hàng thành công (DELIVERED, COMPLETED)
    const [items] = await pool.query(`
      SELECT 
        o.order_id,
        o.create_datetime,
        od.product_version_id,
        p.product_name,
        p.warranty_period,
        COALESCE((
          SELECT vi.image 
          FROM version_image vi 
          WHERE vi.product_version_id = od.product_version_id 
          LIMIT 1
        ), pv.picture, p.picture) as image
      FROM orders o
      JOIN order_details od ON o.order_id = od.order_id
      JOIN product_versions pv ON od.product_version_id = pv.product_version_id
      JOIN products p ON pv.product_id = p.product_id
      WHERE o.customer_id = ? 
        AND o.status IN ('DELIVERED', 'COMPLETED')
        AND p.warranty_period IS NOT NULL
        AND p.warranty_period > 0
      ORDER BY o.create_datetime DESC
    `, [customerId]);

    const result = items.map(d => {
      // Tính ngày hết hạn bảo hành
      const wDate = new Date(d.create_datetime);
      wDate.setMonth(wDate.getMonth() + Number(d.warranty_period));

      return {
        orderId: d.order_id,
        productVersionId: d.product_version_id,
        name: d.product_name,
        image: d.image || '',
        warrantyUntil: formatDate(wDate),
        warrantyPeriod: d.warranty_period
      };
    });

    res.json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
};

const getRequests = async (req, res) => {
  try {
    const { customerId } = req.query;
    if (!customerId) {
      return res.status(400).json({ message: 'Missing customerId' });
    }

    const [requests] = await pool.query(`
      SELECT 
        r.request_id,
        r.type,
        r.reason,
        r.status,
        r.admin_note,
        r.appointment_date,
        r.created_at,
        p.product_name,
        COALESCE((
          SELECT vi.image 
          FROM version_image vi 
          WHERE vi.product_version_id = r.product_version_id 
          LIMIT 1
        ), pv.picture, p.picture) as image
      FROM return_warranty_requests r
      JOIN product_versions pv ON r.product_version_id = pv.product_version_id
      JOIN products p ON pv.product_id = p.product_id
      WHERE r.customer_id = ?
      ORDER BY r.created_at DESC
    `, [customerId]);

    const result = requests.map(r => ({
      requestId: r.request_id,
      type: r.type,
      reason: r.reason,
      status: r.status, // 'pending', 'accepted', 'rejected', 'in_progress', 'completed'
      adminNote: r.admin_note,
      appointmentDate: r.appointment_date ? formatDate(r.appointment_date) : null,
      createdAt: formatDate(r.created_at),
      productName: r.product_name,
      image: r.image || ''
    }));

    res.json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
};

const createRequest = async (req, res) => {
  try {
    const { customerId, orderId, productVersionId, reason, appointmentDate } = req.body;

    if (!customerId || !orderId || !productVersionId || !reason) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const apptDate = appointmentDate ? new Date(appointmentDate) : null;

    const [result] = await pool.query(`
      INSERT INTO return_warranty_requests 
      (order_id, customer_id, product_version_id, type, reason, status, appointment_date)
      VALUES (?, ?, ?, 'warranty', ?, 'pending', ?)
    `, [orderId, customerId, productVersionId, reason, apptDate]);

    res.status(201).json({ 
      message: 'Warranty request created successfully',
      requestId: result.insertId 
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
};

module.exports = {
  getEligibleItems,
  getRequests,
  createRequest
};
