import { User } from '../models/User.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const getUser = asyncHandler(async (req, res) => {
  const u = await User.findById(req.params.id);
  if (!u) return res.status(404).json({ message: 'User not found' });
  res
    .status(200)
    .json({
      userId: u._id,
      email: u.email,
      name: u.name,
      avatar: u.avatar,
      publicKey: u.publicKey,
    });
});

export const findByEmail = asyncHandler(async (req, res) => {
  const { email } = req.query;
  if (!email) return res.status(400).json({ message: 'email is required' });
  const u = await User.findOne({ email });
  if (!u) return res.status(404).json({ message: 'Not found' });
  res
    .status(200)
    .json({
      userId: u._id,
      email: u.email,
      name: u.name,
      avatar: u.avatar,
      publicKey: u.publicKey,
    });
});
