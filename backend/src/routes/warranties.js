const express = require('express');
const router = express.Router();
const warrantyController = require('../controllers/warrantyController');

// All warranty routes should require authentication
// But for simplicity and aligning with other routes, we'll extract customerId from req.query or req.body

router.get('/api/warranties/eligible-items', warrantyController.getEligibleItems);
router.get('/api/warranties', warrantyController.getRequests);
router.post('/api/warranties', warrantyController.createRequest);

module.exports = router;
