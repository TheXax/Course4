import express from 'express';
import { authMiddleware, adminOnly } from '../utils/auth.js';
import { listGenres, createGenre, updateGenre, deleteGenre } from '../controllers/genresController.js';

const router = express.Router();

router.get('/', listGenres);
router.use(authMiddleware, adminOnly);
router.post('/', createGenre);
router.put('/:id', updateGenre);
router.delete('/:id', deleteGenre);

export default router;

