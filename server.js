import http from 'http';
import dotenv from 'dotenv';
import { createApp } from './app.js';
import { connectDB } from './config/db.js';
import { waitForPrimary } from './utils/waitForPrimary.js';
import { createWsServer } from './services/ws.js';
import { startMessageChangeStream } from './services/changeStream.js';

dotenv.config();

const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI;

const app = createApp();
const server = http.createServer(app);
createWsServer(server);

connectDB(MONGO_URI).then(async (conn) => {
  await waitForPrimary(conn); // đợi PRIMARY để Change Stream chắc chắn chạy
  console.log('PRIMARY is ready, starting Change Stream...');
  startMessageChangeStream();
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
