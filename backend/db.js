require('dotenv').config({ override: true });
const mysql = require('mysql2/promise');

/**
 * MySQL connection pool dùng chung cho mọi endpoint backend.
 * Feature mới chỉ cần: const pool = require('./db');
 */
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: { rejectUnauthorized: false },
  // Đọc TIMESTAMP/DATETIME từ MySQL theo UTC — tránh lệch 7h trên máy dev VN.
  timezone: 'Z',
  waitForConnections: true,
  connectionLimit: 10,
});

pool.on('connection', (connection) => {
  connection.query("SET time_zone = '+00:00'");
});

module.exports = pool;
