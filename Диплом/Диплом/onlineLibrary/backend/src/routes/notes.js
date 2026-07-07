import express from 'express';
import { authMiddleware } from '../utils/auth.js';
import { getAllUserNotes, getNotes, createNote, updateNote, deleteNote } from '../controllers/notesController.js';

const router = express.Router();

router.get('/', authMiddleware, getAllUserNotes);
router.get('/:bookId/notes', authMiddleware, getNotes);
router.post('/:bookId/notes', authMiddleware, createNote);
router.put('/notes/:id', authMiddleware, updateNote);
router.delete('/notes/:id', authMiddleware, deleteNote);

export default router;