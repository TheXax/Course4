import express from 'express';
import { authMiddleware } from '../utils/auth.js';
import { getAllUserQuotes, getQuotes, createQuote, deleteQuote } from '../controllers/quotesController.js';

const router = express.Router();

router.get('/', authMiddleware, getAllUserQuotes);
router.get('/:bookId/quotes', authMiddleware, getQuotes);
router.post('/:bookId/quotes', authMiddleware, createQuote);
router.delete('/quotes/:id', authMiddleware, deleteQuote);

export default router;