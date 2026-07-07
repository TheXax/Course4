import express from 'express';
import { authMiddleware } from '../utils/auth.js';
import { listCollections, createCollection, getCollection, addBookToCollection, removeBookFromCollection, removeCollection, updateCollection } from '../controllers/collectionsController.js';
const router = express.Router();

router.use(authMiddleware);
router.get('/', listCollections);
router.get('/:collectionId', getCollection);
router.post('/', createCollection);
router.post('/:collectionId/books/:bookId', addBookToCollection);
router.delete('/:collectionId/books/:bookId', removeBookFromCollection);
router.delete('/:collectionId', removeCollection);
router.put('/:collectionId', updateCollection);

export default router;
