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
  waitForConnections: true,
  connectionLimit: 10,
});

module.exports = pool;
