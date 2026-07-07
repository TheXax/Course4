import express from 'express';
import { authMiddleware } from '../utils/auth.js';
import { getProfile, updateProfile, deleteProfile } from '../controllers/profileController.js';

const router = express.Router();

router.use(authMiddleware);
router.get('/', getProfile);
router.put('/', updateProfile);
router.delete('/', deleteProfile);

export default router;

