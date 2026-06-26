const bcrypt = require('bcryptjs');

function mapCustomerUser(row) {
  return {
    id: String(row.customer_id),
    name: row.full_name ?? 'Khách hàng',
    email: row.email ?? '',
    phoneNumber: row.phone_number ?? null,
    role: 'user',
    accountType: 'customer',
  };
}

function mapEmployeeUser(row, roles) {
  const roleList = roles ? roles.split(',').map((r) => r.trim()).filter(Boolean) : [];
  // Mọi nhân viên (ADMIN, SALE, CS, …) đều có thể hỗ trợ khách qua chat.
  return {
    id: String(row.id),
    name: row.full_name,
    email: row.email,
    phoneNumber: null,
    role: 'staff',
    accountType: 'employee',
    employeeRoles: roleList,
  };
}

async function findCustomerByLogin(pool, email, phoneNumber) {
  const normalizedEmail = String(email ?? '').trim().toLowerCase();
  const normalizedPhone = String(phoneNumber ?? '').trim();

  if (normalizedEmail) {
    const [rows] = await pool.query(
      `SELECT * FROM customers
       WHERE LOWER(email) = ?
       LIMIT 1`,
      [normalizedEmail],
    );
    if (rows.length > 0) {
      if (normalizedPhone && rows[0].phone_number && rows[0].phone_number !== normalizedPhone) {
        return null;
      }
      return rows[0];
    }
  }

  if (normalizedPhone) {
    const [rows] = await pool.query(
      `SELECT * FROM customers WHERE phone_number = ? LIMIT 1`,
      [normalizedPhone],
    );
    if (rows.length > 0) return rows[0];
  }

  return null;
}

async function findEmployeeByEmail(pool, email) {
  const [rows] = await pool.query(
    `
    SELECT e.*, GROUP_CONCAT(DISTINCT r.name ORDER BY r.name SEPARATOR ', ') AS roles
    FROM employees e
    LEFT JOIN employee_roles er ON er.employee_id = e.id
    LEFT JOIN roles r ON r.id = er.role_id
    WHERE LOWER(e.email) = LOWER(?) AND e.is_active = 1
    GROUP BY e.id, e.email, e.password_hash, e.full_name, e.is_active, e.created_at, e.updated_at
    LIMIT 1
    `,
    [email.trim()],
  );
  return rows[0] ?? null;
}

function setupAuth(app, pool) {
  app.post('/auth/login', async (req, res) => {
    try {
      const { email, password, phoneNumber } = req.body ?? {};
      if (!email && !phoneNumber) {
        return res.status(400).json({
          message: 'Email hoặc số điện thoại là bắt buộc',
          code: 'AUTH_BAD_REQUEST',
        });
      }

      // 1) Nhân viên — email + password (bcrypt)
      if (email && password) {
        const employee = await findEmployeeByEmail(pool, email);
        if (employee) {
          if (!employee.password_hash) {
            return res.status(401).json({
              message: 'Tài khoản nhân viên chưa có mật khẩu. Liên hệ quản trị.',
              code: 'AUTH_NO_PASSWORD',
            });
          }
          const ok = await bcrypt.compare(password, employee.password_hash);
          if (!ok) {
            return res.status(401).json({
              message: 'Email hoặc mật khẩu không đúng',
              code: 'AUTH_INVALID',
            });
          }
          return res.json({ user: mapEmployeeUser(employee, employee.roles) });
        }
      }

      // 2) Khách hàng — tra cứu bảng customers (không có cột password)
      const customer = await findCustomerByLogin(pool, email, phoneNumber);
      if (customer) {
        return res.json({ user: mapCustomerUser(customer) });
      }

      return res.status(401).json({
        message: 'Không tìm thấy tài khoản khách hàng hoặc nhân viên',
        code: 'AUTH_INVALID',
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: err.message, code: 'AUTH_LOGIN_ERROR' });
    }
  });

  app.post('/auth/register', async (req, res) => {
    try {
      const { name, email, phoneNumber } = req.body ?? {};
      const fullName = String(name ?? '').trim();
      const normalizedEmail = String(email ?? '').trim().toLowerCase() || null;
      const normalizedPhone = String(phoneNumber ?? '').trim() || null;

      if (!fullName) {
        return res.status(400).json({ message: 'Họ tên là bắt buộc', code: 'AUTH_BAD_REQUEST' });
      }
      if (!normalizedEmail && !normalizedPhone) {
        return res.status(400).json({
          message: 'Cần email hoặc số điện thoại',
          code: 'AUTH_BAD_REQUEST',
        });
      }

      if (normalizedEmail) {
        const [existingEmail] = await pool.query(
          'SELECT customer_id FROM customers WHERE LOWER(email) = ? LIMIT 1',
          [normalizedEmail],
        );
        if (existingEmail.length > 0) {
          return res.status(409).json({ message: 'Email đã được đăng ký', code: 'AUTH_EMAIL_EXISTS' });
        }
      }

      if (normalizedPhone) {
        const [existingPhone] = await pool.query(
          'SELECT customer_id FROM customers WHERE phone_number = ? LIMIT 1',
          [normalizedPhone],
        );
        if (existingPhone.length > 0) {
          return res.status(409).json({ message: 'Số điện thoại đã được đăng ký', code: 'AUTH_PHONE_EXISTS' });
        }
      }

      const [result] = await pool.query(
        `INSERT INTO customers (full_name, email, phone_number, create_at, update_at)
         VALUES (?, ?, ?, NOW(), NOW())`,
        [fullName, normalizedEmail, normalizedPhone],
      );

      const [rows] = await pool.query('SELECT * FROM customers WHERE customer_id = ?', [
        result.insertId,
      ]);

      res.status(201).json({ user: mapCustomerUser(rows[0]) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: err.message, code: 'AUTH_REGISTER_ERROR' });
    }
  });
}

module.exports = { setupAuth, mapCustomerUser };
