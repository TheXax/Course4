import express from 'express';
import { authMiddleware } from '../utils/auth.js';
import { listFavorites, addFavorite, removeFavorite } from '../controllers/favoritesController.js';

const router = express.Router();

router.use(authMiddleware);
router.get('/', listFavorites);
router.post('/:bookId', addFavorite);
router.delete('/:bookId', removeFavorite);

export default router;

