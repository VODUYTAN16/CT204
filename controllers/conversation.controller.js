// controllers/conversation.controller.js
import mongoose from 'mongoose';
import { User } from '../models/User.js';
import { Conversation } from '../models/Conversation.js';
import { Membership } from '../models/Membership.js'; // giữ như cũ cho group
import { Message } from '../models/Message.js';
import { MessageKey } from '../models/MessageKey.js';

// GET /conversations?userId=<me>
export const listMyConversations = async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ message: 'Missing userId' });

    const mems = await Membership.find(
      { userId, status: 'active' },
      'conversationId'
    ).lean();
    const ids = mems.map((m) => m.conversationId);

    const convs = await Conversation.find({ _id: { $in: ids } })
      .sort({ lastMessageAt: -1, updatedAt: -1 })
      .lean();

    res.json(convs);
  } catch (e) {
    res.status(500).json({ message: 'Error fetching conversations' });
  }
};

// POST /conversations/direct { a, b }
export const openOrCreateDirect = async (req, res) => {
  try {
    let { a, b } = req.body;
    if (!a || !b) return res.status(400).json({ message: 'Missing members' });
    if (a === b) return res.status(400).json({ message: 'Invalid pair' });

    // chuẩn hóa thứ tự a,b để khớp unique index
    const [A, B] = [a.toString(), b.toString()].sort();

    // tìm direct có sẵn
    const existed = await Conversation.findOne({
      type: 'direct',
      'directPair.a': A,
      'directPair.b': B,
    }).lean();

    if (existed) {
      // đảm bảo membership tồn tại
      await Membership.updateOne(
        { conversationId: existed._id, userId: a },
        { $setOnInsert: { role: 'member', status: 'active' } },
        { upsert: true }
      );
      await Membership.updateOne(
        { conversationId: existed._id, userId: b },
        { $setOnInsert: { role: 'member', status: 'active' } },
        { upsert: true }
      );
      return res.json({ conversationId: existed._id });
    }

    // tạo mới
    const conv = await Conversation.create({
      type: 'direct',
      directPair: { a: A, b: B },
    });

    await Membership.insertMany([
      { conversationId: conv._id, userId: a, role: 'member' },
      { conversationId: conv._id, userId: b, role: 'member' },
    ]);

    res.json({ conversationId: conv._id });
  } catch (e) {
    // có thể dính duplicate key nếu race condition -> tìm lại
    if (e?.code === 11000) {
      const [A, B] = [req.body.a.toString(), req.body.b.toString()].sort();
      const found = await Conversation.findOne({
        type: 'direct',
        'directPair.a': A,
        'directPair.b': B,
      }).lean();
      if (found) return res.json({ conversationId: found._id });
    }
    res.status(500).json({ message: 'Error creating/opening direct' });
  }
};

// POST /conversations/group { title, createdBy, memberIds }
export const createGroup = async (req, res) => {
  try {
    let { title, createdBy, memberIds } = req.body;
    if (!title || !createdBy || !Array.isArray(memberIds)) {
      return res.status(400).json({ message: 'Missing fields' });
    }
    title = title.trim();

    const set = new Set(memberIds.map(String));
    set.add(String(createdBy));
    memberIds = Array.from(set);

    if (memberIds.length < 3) {
      return res
        .status(400)
        .json({ message: 'Nhóm cần tối thiểu 3 thành viên' });
    }

    const conv = await Conversation.create({
      type: 'group',
      title,
      createdBy,
    });

    await Membership.insertMany(
      memberIds.map((uid) => ({
        conversationId: conv._id,
        userId: uid,
        role: uid === String(createdBy) ? 'owner' : 'member',
      })),
      { ordered: false }
    );

    res.json({ conversationId: conv._id });
  } catch (e) {
    res.status(500).json({ message: 'Error creating group' });
  }
};

// GET /conversations/:id/members
export const getMembers = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id))
      return res.status(400).json({ message: 'Invalid id' });

    const mems = await Membership.find(
      { conversationId: id, status: 'active' },
      'userId'
    ).lean();
    const uids = mems.map((m) => m.userId);
    const users = await User.find(
      { _id: { $in: uids } },
      '_id name email avatar publicKey'
    ).lean();

    res.json(
      users.map((u) => ({
        userId: u._id,
        name: u.name,
        email: u.email,
        publicKey: u.publicKey,
        avatar: u.avatar,
      }))
    );
  } catch (e) {
    res.status(500).json({ message: 'Error fetching members' });
  }
};

// POST /conversations/:id/members { userId }
export const addMember = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;
    if (!id || !userId)
      return res.status(400).json({ message: 'Missing fields' });

    const conv = await Conversation.findById(id).lean();
    if (!conv)
      return res.status(404).json({ message: 'Conversation not found' });
    if (conv.type !== 'group')
      return res
        .status(400)
        .json({ message: 'Only group allows adding members' });

    await Membership.updateOne(
      { conversationId: id, userId },
      { $setOnInsert: { role: 'member', status: 'active' } },
      { upsert: true }
    );

    res.json({ ok: 1 });
  } catch (e) {
    res.status(500).json({ message: 'Error adding member' });
  }
};

// DELETE /conversations/:id/members/:userId
export const removeMember = async (req, res) => {
  try {
    const { id, userId } = req.params;
    await Membership.deleteOne({ conversationId: id, userId });
    res.json({ ok: 1 });
  } catch (e) {
    res.status(500).json({ message: 'Error removing member' });
  }
};

// PATCH /conversations/:id { title }
export const renameGroup = async (req, res) => {
  try {
    const { id } = req.params;
    const { title } = req.body;
    if (!title) return res.status(400).json({ message: 'Missing title' });

    const conv = await Conversation.findById(id);
    if (!conv)
      return res.status(404).json({ message: 'Conversation not found' });
    if (conv.type !== 'group')
      return res.status(400).json({ message: 'Only group can be renamed' });

    conv.title = title.trim();
    await conv.save();
    res.json({ ok: 1 });
  } catch (e) {
    res.status(500).json({ message: 'Error renaming group' });
  }
};

// DELETE /conversations/:id
export const deleteConversation = async (req, res) => {
  try {
    const { id } = req.params;

    const msgs = await Message.find({ conversationId: id }, '_id').lean();
    const msgIds = msgs.map((m) => m._id);

    await Promise.all([
      Conversation.deleteOne({ _id: id }),
      Membership.deleteMany({ conversationId: id }),
      Message.deleteMany({ conversationId: id }),
      MessageKey.deleteMany({ messageId: { $in: msgIds } }),
    ]);

    res.json({ ok: 1 });
  } catch (e) {
    res.status(500).json({ message: 'Error deleting conversation' });
  }
};
