import express from 'express';
import { authMiddleware } from '../utils/auth.js';
import { listRead, addToRead, removeFromRead } from '../controllers/readController.js';

const router = express.Router();

router.get('/', authMiddleware, listRead);
router.post('/:bookId', authMiddleware, addToRead);
router.delete('/:bookId', authMiddleware, removeFromRead);

export default router;
