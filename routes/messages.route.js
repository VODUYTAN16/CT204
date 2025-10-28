// routes/messages.route.js
import { Router } from 'express';
import {
  listMessages,
  getMessageKeyForUser,
  sendMessage,
} from '../controllers/message.controller.js';

const router = Router();

router.get('/', listMessages);
router.get('/key', getMessageKeyForUser);
router.post('/', sendMessage);

export default router;
