const express = require('express');
const router = express.Router();
const ordersController = require('./orders.controller');

// GET /api/orders?customerId=...
router.get('/', ordersController.getOrders);

// GET /api/orders/:id?customerId=...
router.get('/:id', ordersController.getOrderDetails);

module.exports = router;
