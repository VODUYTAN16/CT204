import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import routes from './routes/index.js';

export function createApp() {
  const app = express();
  app.use(cors());
  app.use(bodyParser.json());
  app.use('/uploads', express.static('uploads'));
  app.use(routes);
  app.use((req, res) => res.status(404).json({ message: 'Route not found' }));
  app.use((err, req, res, next) => {
    console.error(err);
    res
      .status(res.statusCode !== 200 ? res.statusCode : 500)
      .json({ message: err.message || 'Server error' });
  });
  return app;
}
