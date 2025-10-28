// controllers/friendship.controller.js
import { User } from '../models/User.js';
import { Friendship } from '../models/Friendship.js';

// GET /friendships?userId=<me>  -> danh sách bạn (accepted)
export const listFriends = async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ message: 'Missing userId' });

    const edges = await Friendship.find({
      status: 'accepted',
      $or: [{ requesterId: userId }, { addresseeId: userId }],
    }).lean();

    const friendIds = edges.map((e) =>
      e.requesterId.toString() === userId ? e.addresseeId : e.requesterId
    );

    const friends = await User.find(
      { _id: { $in: friendIds } },
      '_id name email avatar mypublickey'
    ).lean();

    res.json(friends);
  } catch (e) {
    res.status(500).json({ message: 'Error fetching friends' });
  }
};

// GET /friendships/pending?userId=<me> -> yêu cầu đến (incoming)
export const listIncomingRequests = async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ message: 'Missing userId' });

    const reqs = await Friendship.find({
      status: 'pending',
      addresseeId: userId,
    })
      .populate('requesterId', '_id name email avatar')
      .lean();

    res.json(
      reqs.map((r) => ({
        _id: r._id,
        requester: r.requesterId,
        createdAt: r.createdAt,
      }))
    );
  } catch (e) {
    res.status(500).json({ message: 'Error fetching pending requests' });
  }
};

// POST /friendships/request { requesterId, email }
export const requestFriendByEmail = async (req, res) => {
  try {
    const { requesterId, email } = req.body;
    if (!requesterId || !email)
      return res.status(400).json({ message: 'Missing fields' });

    const target = await User.findOne({
      email: email.trim().toLowerCase(),
    }).lean();
    if (!target) return res.status(404).json({ message: 'User not found' });
    if (target._id.toString() === requesterId) {
      return res.status(400).json({ message: 'Cannot friend yourself' });
    }

    const existed = await Friendship.findOne({
      $or: [
        { requesterId, addresseeId: target._id },
        { requesterId: target._id, addresseeId: requesterId },
      ],
    }).lean();

    if (existed)
      return res.status(409).json({ message: 'Friendship exists or pending' });

    const doc = await Friendship.create({
      requesterId,
      addresseeId: target._id,
      status: 'pending',
    });

    res.json({ ok: 1, requestId: doc._id });
  } catch (e) {
    res.status(500).json({ message: 'Error creating request' });
  }
};

// POST /friendships/:requestId/accept
export const acceptFriendRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const doc = await Friendship.findById(requestId);
    if (!doc) return res.status(404).json({ message: 'Request not found' });

    doc.status = 'accepted';
    await doc.save();
    res.json({ ok: 1 });
  } catch (e) {
    res.status(500).json({ message: 'Error accepting request' });
  }
};

// DELETE /friendships/between?userId=<me>&friendId=<id>
export const deleteFriendshipBetween = async (req, res) => {
  try {
    const { userId, friendId } = req.query;
    if (!userId || !friendId)
      return res.status(400).json({ message: 'Missing params' });

    await Friendship.deleteOne({
      $or: [
        { requesterId: userId, addresseeId: friendId },
        { requesterId: friendId, addresseeId: userId },
      ],
    });

    res.json({ ok: 1 });
  } catch (e) {
    res.status(500).json({ message: 'Error deleting friendship' });
  }
};
