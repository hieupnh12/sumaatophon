const pool = require('../../db');

function formatCurrency(amount) {
  if (!amount) return '0đ';
  return Number(amount).toLocaleString('vi-VN') + 'đ';
}

function formatDate(dateString) {
  if (!dateString) return '';
  const date = new Date(dateString);
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = date.getFullYear();
  return `${day}/${month}/${year}`;
}

function mapStatus(status) {
  switch (status) {
    case 'PENDING': return 'pending';
    case 'PAID': return 'pending';
    case 'SHIPPED': return 'shipping';
    case 'DELIVERED': return 'completed';
    case 'COMPLETED': return 'completed';
    case 'CANCELED': return 'cancelled';
    case 'RETURNED': return 'return';
    default: return 'pending';
  }
}

function mapStatusText(status) {
  switch (status) {
    case 'PENDING': return 'Chờ xác nhận';
    case 'PAID': return 'Đã thanh toán';
    case 'SHIPPED': return 'Đang giao hàng';
    case 'DELIVERED': return 'Đã nhận hàng';
    case 'COMPLETED': return 'Hoàn tất';
    case 'CANCELED': return 'Đã hủy';
    case 'RETURNED': return 'Đổi trả';
    default: return 'Đang xử lý';
  }
}

const getOrders = async (req, res) => {
  try {
    const { customerId } = req.query;
    if (!customerId) {
      return res.status(400).json({ message: 'Missing customerId' });
    }

    const [orders] = await pool.query(`
      SELECT 
        o.order_id, 
        o.status, 
        o.create_datetime, 
        o.total_amount,
        o.is_paid,
        (SELECT COUNT(order_detail_id) FROM order_details WHERE order_id = o.order_id) as total_items,
        (
          SELECT p.product_name 
          FROM order_details od
          JOIN product_versions pv ON od.product_version_id = pv.product_version_id
          JOIN products p ON pv.product_id = p.product_id
          WHERE od.order_id = o.order_id 
          LIMIT 1
        ) as product_name,
        (
          SELECT pv.export_price 
          FROM order_details od
          JOIN product_versions pv ON od.product_version_id = pv.product_version_id
          WHERE od.order_id = o.order_id 
          LIMIT 1
        ) as product_price,
        (
          SELECT vi.image 
          FROM order_details od
          JOIN version_image vi ON od.product_version_id = vi.product_version_id
          WHERE od.order_id = o.order_id 
          LIMIT 1
        ) as product_image
      FROM orders o
      WHERE o.customer_id = ?
      ORDER BY o.create_datetime DESC
    `, [customerId]);

    const result = orders.map(row => {
      const formattedId = `#ORD${String(row.order_id).padStart(6, '0')}`;
      return {
        id: formattedId,
        realId: row.order_id,
        status: mapStatus(row.status),
        statusText: mapStatusText(row.status),
        items: row.total_items,
        total: formatCurrency(row.total_amount),
        date: formatDate(row.create_datetime),
        product: row.product_name || 'Sản phẩm',
        productPrice: formatCurrency(row.product_price),
        hasVat: true,
        otherItemsCount: Math.max(0, row.total_items - 1),
        productImage: row.product_image || ''
      };
    });

    res.json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
};

const getOrderDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const { customerId } = req.query;

    if (!customerId) {
      return res.status(400).json({ message: 'Missing customerId' });
    }

    const [orders] = await pool.query(`
      SELECT o.*, 
             c.full_name as customer_name, 
             c.phone_number as customer_phone, 
             c.address as customer_address
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.customer_id
      WHERE o.order_id = ? AND o.customer_id = ?
    `, [id, customerId]);

    if (orders.length === 0) {
      return res.status(404).json({ message: 'Order not found' });
    }

    const order = orders[0];

    const [details] = await pool.query(`
      SELECT 
        od.order_detail_id,
        od.product_version_id,
        od.unit_price_after,
        od.quantity,
        p.product_name,
        p.warranty_period,
        (
          SELECT vi.image 
          FROM version_image vi 
          WHERE vi.product_version_id = od.product_version_id 
          LIMIT 1
        ) as image
      FROM order_details od
      JOIN product_versions pv ON od.product_version_id = pv.product_version_id
      JOIN products p ON pv.product_id = p.product_id
      WHERE od.order_id = ?
    `, [id]);

    const formattedId = `#ORD${String(order.order_id).padStart(6, '0')}`;

    const timeline = [];
    timeline.push({ title: 'Đặt hàng thành công', date: order.create_datetime, isDone: true });
    timeline.push({ title: 'Sẵn sàng', date: null, isDone: order.status !== 'PENDING' });
    timeline.push({ title: 'Đã nhận hàng', date: order.end_datetime, isDone: order.status === 'DELIVERED' || order.status === 'COMPLETED' });

    res.json({
      id: formattedId,
      status: mapStatus(order.status),
      statusText: mapStatusText(order.status),
      date: formatDate(order.create_datetime),
      totalAmount: formatCurrency(order.total_amount),
      isPaid: order.is_paid === 1,
      customer: {
        name: order.customer_name || 'Khách hàng',
        phone: order.customer_phone || '',
        address: order.customer_address || '',
        note: order.note || '-'
      },
      paymentInfo: {
        totalItems: details.length,
        subtotal: formatCurrency(order.total_amount),
        discount: '-0đ',
        shippingFee: 'Miễn phí',
        totalVat: formatCurrency(order.total_amount),
        amountPaid: order.is_paid === 1 ? formatCurrency(order.total_amount) : '0đ',
        amountRemaining: order.is_paid === 1 ? '0đ' : formatCurrency(order.total_amount),
      },
      items: details.map(d => {
        const wDate = new Date();
        wDate.setMonth(wDate.getMonth() + (Number(d.warranty_period) || 12));

        return {
          id: d.order_detail_id,
          name: d.product_name,
          price: formatCurrency(d.unit_price_after),
          warrantyUntil: formatDate(wDate),
          quantity: d.quantity,
          image: d.image || ''
        };
      }),
      timeline: timeline
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
};

module.exports = {
  getOrders,
  getOrderDetails,
};
