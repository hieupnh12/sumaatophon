const productsRouter = require('./products');
const authRouter = require('./auth');
const profileRouter = require('./profile');
const addressesRouter = require('./addresses');
const cartRouter = require('./cart');
const ordersRouter = require('./orders');
const paymentsRouter = require('./payments');
const healthRouter = require('./health');
const notificationsRouter = require('./notifications');
const warrantiesRouter = require('./warranties');

function registerRoutes(app) {
  app.use(productsRouter);
  app.use(authRouter);
  app.use(profileRouter);
  app.use(addressesRouter);
  app.use(cartRouter);
  app.use(ordersRouter);
  app.use(paymentsRouter);
  app.use(notificationsRouter);
  app.use(warrantiesRouter);
  app.use(healthRouter);
}

module.exports = registerRoutes;
