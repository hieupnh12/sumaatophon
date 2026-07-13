const express = require('express');
const pool = require('../../db');

const router = express.Router();

function parseCoordinate(value) {
  const num = Number(value);
  if (!Number.isFinite(num)) return null;
  return num;
}

function haversineKm(lat1, lng1, lat2, lng2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// GET /stores — danh sách cửa hàng; ?lat=&lng= để sắp xếp theo khoảng cách
router.get('/stores', async (req, res) => {
  try {
    const lat = parseCoordinate(req.query.lat);
    const lng = parseCoordinate(req.query.lng);
    const hasUserLocation = lat != null && lng != null;

    const [rows] = await pool.query(
      `SELECT store_id, name, address, phone, latitude, longitude, open_time
       FROM stores
       WHERE is_active = 1
       ORDER BY store_id ASC`,
    );

    const stores = rows.map((row) => {
      const store = {
        id: String(row.store_id),
        name: row.name,
        address: row.address,
        phone: row.phone,
        latitude: Number(row.latitude),
        longitude: Number(row.longitude),
        openTime: row.open_time,
      };

      if (hasUserLocation) {
        store.distanceKm = Math.round(
          haversineKm(lat, lng, store.latitude, store.longitude) * 10,
        ) / 10;
      }

      return store;
    });

    if (hasUserLocation) {
      stores.sort((a, b) => (a.distanceKm ?? 0) - (b.distanceKm ?? 0));
    }

    res.json(stores);
  } catch (err) {
    console.error('[stores] list error:', err.message);
    res.status(500).json({ message: err.message, code: 'STORES_LIST_ERROR' });
  }
});

module.exports = router;
