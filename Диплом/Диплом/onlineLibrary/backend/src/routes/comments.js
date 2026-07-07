import express from 'express';
import { authMiddleware, adminOnly } from '../utils/auth.js';
import { addComment, listComments, deleteComment, replyToComment } from '../controllers/commentsController.js';
const router = express.Router();

router.delete('/id/:commentId', authMiddleware, deleteComment);
router.get('/:bookId', listComments);
router.post('/:bookId', authMiddleware, addComment);
router.post('/:commentId/reply', authMiddleware, adminOnly, replyToComment);

export default router;
