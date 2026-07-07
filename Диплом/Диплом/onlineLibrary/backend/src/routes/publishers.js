import express from 'express';
import { authMiddleware, adminOnly } from '../utils/auth.js';
import { listPublishers, createPublisher, updatePublisher, deletePublisher } from '../controllers/publishersController.js';

const router = express.Router();

router.get('/', listPublishers);
router.use(authMiddleware, adminOnly);
router.post('/', createPublisher);
router.put('/:id', updatePublisher);
router.delete('/:id', deletePublisher);

export default router;

