const express = require('express');
const cors = require('cors');
const path = require('path');
const registerRoutes = require('./routes');

function createApp() {
  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
  registerRoutes(app);
  return app;
}

module.exports = createApp;
