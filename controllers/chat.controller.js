import mongoose from 'mongoose';
import { ListChat } from '../models/ListChat.js';
import { User } from '../models/User.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const getChatList = asyncHandler(async (req, res) => {
  const list = await ListChat.find({});
  const data = list.map((c) => ({
    id: c._id,
    title: c.title,
    messages: c.messages,
  }));
  res.status(200).json(data);
});

export const createNewChat = asyncHandler(async (req, res) => {
  const { newChatTitle } = req.body;
  if (!newChatTitle)
    return res.status(400).json({ message: 'Chat title is required' });
  const chat = await ListChat.create({ title: newChatTitle, messages: [] });
  res.status(200).json({ chatId: chat._id, title: chat.title });
});

export const getMessagesByChatId = asyncHandler(async (req, res) => {
  const chat = await ListChat.findById(req.params.chatId);
  if (!chat) return res.status(404).json({ message: 'Chat not found' });
  res
    .status(200)
    .json({ chatId: chat._id, title: chat.title, messages: chat.messages });
});

export const deleteChat = asyncHandler(async (req, res) => {
  const deleted = await ListChat.findByIdAndDelete(req.params.chatId);
  if (!deleted) return res.status(404).json({ message: 'Chat not found' });
  res
    .status(200)
    .json({
      message: 'Chat deleted successfully',
      deletedChatId: req.params.chatId,
    });
});

export const sendMessage = asyncHandler(async (req, res) => {
  const { chatId, sender, text, encryptAes, clientMessageId } = req.body;
  if (!chatId || !sender || !text || !encryptAes) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const chat = await ListChat.findById(chatId);
  if (!chat) return res.status(404).json({ message: 'Chat not found' });

  const user = await User.findById(sender);
  if (!user) return res.status(404).json({ message: 'Sender not found' });

  const newMessage = {
    _id: new mongoose.Types.ObjectId(),
    clientMessageId,
    sender,
    text,
    name: user.name,
    avatar: user.avatar,
    captions: null,
    timestamp: new Date(),
    encryptAes: encryptAes.map((i) => ({
      userId: i.userId,
      encryptedAesKey: i.encryptedAesKey,
    })),
  };

  chat.messages.push(newMessage);
  await chat.save();

  res.status(200).json({ chatId: chat._id, newMessage });
});
