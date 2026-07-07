import express from 'express';
import { authMiddleware } from '../utils/auth.js';
import { getReadingProgress, updateReadingProgress } from '../controllers/readingController.js';

const router = express.Router();

router.get('/:bookId/progress', authMiddleware, getReadingProgress);
router.put('/:bookId/progress', authMiddleware, updateReadingProgress);

export default router;