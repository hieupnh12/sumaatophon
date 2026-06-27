const http = require('http');
const { Server } = require('socket.io');
const createApp = require('./src/app');
const pool = require('./db');
const { setupAuth } = require('./auth');
const { setupChat } = require('./chat');
const { setupChatbot } = require('./chatbot');

const app = createApp();
const port = Number(process.env.PORT) || 3000;

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' },
});

setupAuth(app, pool);
setupChat(app, io, pool);
setupChatbot(app, pool);

server.listen(port, () => {
  console.log(`PhoneShop API listening on http://localhost:${port}`);
  console.log('Push notifications: FCM enabled (firebase-admin/messaging)');
  console.log('Chat: REST /chat/* + Socket.IO enabled');
  console.log('Chatbot: REST /chatbot/* enabled');
}).on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${port} đang được dùng. Dừng server cũ rồi chạy lại.`);
    process.exit(1);
  }
  throw err;
});
