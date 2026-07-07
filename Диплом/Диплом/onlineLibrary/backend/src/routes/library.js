import express from 'express';
import { authMiddleware } from '../utils/auth.js';
import { listLibrary, addToLibrary, removeFromLibrary } from '../controllers/libraryController.js';

const router = express.Router();

router.get('/', authMiddleware, listLibrary);
router.post('/:bookId', authMiddleware, addToLibrary);
router.delete('/:bookId', authMiddleware, removeFromLibrary);

export default router;
