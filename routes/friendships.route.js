// routes/friendships.route.js
import { Router } from 'express';
import {
  listFriends,
  listIncomingRequests,
  requestFriendByEmail,
  acceptFriendRequest,
  deleteFriendshipBetween,
} from '../controllers/friendship.controller.js';

const router = Router();

router.get('/', listFriends);
router.get('/pending', listIncomingRequests);
router.post('/request', requestFriendByEmail);
router.post('/:requestId/accept', acceptFriendRequest);
router.delete('/between', deleteFriendshipBetween);

export default router;
