import express from 'express';
import { authMiddleware, adminOnly } from '../utils/auth.js';
import { listAuthors, createAuthor, updateAuthor, deleteAuthor } from '../controllers/authorsController.js';

const router = express.Router();

router.get('/', listAuthors);
router.use(authMiddleware, adminOnly);
router.post('/', createAuthor);
router.put('/:id', updateAuthor);
router.delete('/:id', deleteAuthor);

export default router;

