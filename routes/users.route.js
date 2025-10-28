import { Router } from 'express';
import { getUser, findByEmail } from '../controllers/user.controller.js';
const r = Router();

r.get('/:id', getUser);
r.get('/', findByEmail); // /users?email=...

export default r;
