// controllers/message.controller.js
import mongoose from 'mongoose';
import { Message } from '../models/Message.js';
import { MessageKey } from '../models/MessageKey.js';
import { Conversation } from '../models/Conversation.js';
// controllers/message.controller.js
export const listMessages = async (req, res) => {
  try {
    const { conversationId, limit = 100, before } = req.query;
    if (!conversationId)
      return res.status(400).json({ message: 'Missing conversationId' });

    const q = { conversationId };
    if (before && mongoose.isValidObjectId(before)) {
      q._id = { $lt: new mongoose.Types.ObjectId(before) };
    }

    const items = await Message.find(q)
      .sort({ _id: -1 })
      .limit(Number(limit))
      .populate('senderId', '_id name email avatar') // ⬅️ lấy name + avatar người gửi
      .lean();

    // Chuẩn hóa shape trả về: senderProfile
    const result = items.reverse().map((m) => ({
      ...m,
      senderId: m.senderId?._id?.toString() ?? m.senderId, // giữ nguyên senderId là string
      senderProfile:
        m.senderId && m.senderId._id
          ? {
              _id: m.senderId._id.toString(),
              name: m.senderId.name,
              email: m.senderId.email,
              avatar: m.senderId.avatar,
            }
          : null,
    }));

    res.json(result);
  } catch (e) {
    res.status(500).json({ message: 'Error fetching messages' });
  }
};

// GET /messages/key?messageId=&userId=
export const getMessageKeyForUser = async (req, res) => {
  try {
    const { messageId, userId } = req.query;
    if (!messageId || !userId)
      return res.status(400).json({ message: 'Missing params' });

    const mk = await MessageKey.findOne({ messageId, userId }).lean();
    if (!mk) return res.status(404).json({ message: 'Key not found' });

    res.json({ encryptedAesKey: mk.encryptedAesKey });
  } catch (e) {
    res.status(500).json({ message: 'Error fetching message key' });
  }
};

// POST /messages
export const sendMessage = async (req, res) => {
  try {
    const {
      conversationId,
      senderId,
      clientMessageId,
      kind = 'text',
      text = '',
      media = null,
      captions = null,
      keys = [], // [{ userId, encryptedAesKey }]
    } = req.body;

    if (!conversationId || !senderId || !text) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const now = new Date();

    const doc = await Message.create({
      conversationId,
      senderId,
      clientMessageId,
      kind,
      text,
      media,
      captions,
      timestamp: now,
    });

    if (Array.isArray(keys) && keys.length > 0) {
      const rows = keys.map((k) => ({
        messageId: doc._id,
        userId: k.userId,
        encryptedAesKey: k.encryptedAesKey,
      }));
      await MessageKey.insertMany(rows, { ordered: false });
    }

    // cập nhật conversation.lastMessage*
    await Conversation.updateOne(
      { _id: conversationId },
      { $set: { lastMessageId: doc._id, lastMessageAt: now } }
    );

    res.json({
      ok: 1,
      message: {
        _id: doc._id,
        conversationId: doc.conversationId,
        clientMessageId: doc.clientMessageId,
        senderId: doc.senderId,
        kind: doc.kind,
        text: doc.text,
        media: doc.media,
        captions: doc.captions,
        timestamp: doc.timestamp,
      },
    });
  } catch (e) {
    res.status(500).json({ message: 'Error sending message' });
  }
};
