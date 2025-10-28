import { Router } from 'express';
import auth from './auth.route.js';
import users from './users.route.js';
import friendships from './friendships.route.js';
import conversations from './conversations.route.js';
import messages from './messages.route.js';

const api = Router();

api.use(auth);
api.use('/users', users);
api.use('/friendships', friendships);
api.use('/conversations', conversations);
api.use('/messages', messages);

export default api;
