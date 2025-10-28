// routes/conversations.route.js
import { Router } from 'express';
import {
  listMyConversations,
  openOrCreateDirect,
  createGroup,
  getMembers,
  addMember,
  removeMember,
  renameGroup,
  deleteConversation,
} from '../controllers/conversation.controller.js';

const router = Router();

router.get('/', listMyConversations);
router.post('/direct', openOrCreateDirect);
router.post('/group', createGroup);

router.get('/:id/members', getMembers);
router.post('/:id/members', addMember);
router.delete('/:id/members/:userId', removeMember);

router.patch('/:id', renameGroup);
router.delete('/:id', deleteConversation);

export default router;
