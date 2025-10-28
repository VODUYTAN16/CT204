import { Router } from 'express';
import {
  getChatList,
  createNewChat,
  getMessagesByChatId,
  deleteChat,
  sendMessage,
} from '../controllers/chat.controller.js';

const router = Router();

router.get('/chatlist', getChatList);
router.post('/createNewChat', createNewChat);
router.get('/messages/:chatId', getMessagesByChatId);
router.delete('/deleteChat/:chatId', deleteChat);
router.post('/sendMessage', sendMessage);

export default router;
