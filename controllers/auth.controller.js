import bcrypt from 'bcryptjs';
import { User } from '../models/User.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const register = asyncHandler(async (req, res) => {
  const { email, password, publicKey, name, avatar } = req.body;

  if (!email || !password || !publicKey)
    return res.status(400).json({ message: 'Missing fields' });

  const ex = await User.findOne({ email });
  if (ex) return res.status(400).json({ message: 'User already exists' });

  // Mảng chứa đường dẫn avatar có sẵn
  const avatarList = [
    // 'assets/pic1.jpg',
    // 'assets/pic2.jpg',
    // 'assets/pic3.jpg',
    'assets/pic4.jpg',
    'assets/pic5.jpg',
    'assets/pic6.jpg',
    'assets/pic7.jpg',
  ];

  // Nếu không có avatar trong request thì random 1 cái
  const randomAvatar =
    avatar || avatarList[Math.floor(Math.random() * avatarList.length)];

  const hash = await bcrypt.hash(password, 10);
  const user = await User.create({
    email,
    password: hash,
    publicKey,
    name,
    avatar: randomAvatar,
  });

  res.status(200).json({
    uid: user._id,
    email: user.email,
    name: user.name,
    avatar: user.avatar,
  });
});

export const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const u = await User.findOne({ email });
  if (!u) return res.status(400).json({ message: 'Invalid email or password' });
  const ok = await bcrypt.compare(password, u.password);
  if (!ok)
    return res.status(400).json({ message: 'Invalid email or password' });
  res.status(200).json({
    uid: u._id,
    email: u.email,
    name: u.name,
    avatar: u.avatar,
    publicKey: u.publicKey,
  });
});
