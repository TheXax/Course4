import express from 'express';
import { authMiddleware, adminOnly } from '../utils/auth.js';
import { listUsers, blockUser, unblockUser } from '../controllers/adminController.js';
const router = express.Router();

router.use(authMiddleware, adminOnly);
router.get('/users', listUsers);
router.post('/users/:id/block', blockUser);
router.post('/users/:id/unblock', unblockUser);

export default router;
