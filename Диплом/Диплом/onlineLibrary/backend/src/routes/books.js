import express from 'express';
import multer from 'multer';
import path from 'path';
import { getBooks, getBook, createBook, updateBook, deleteBook, getBookContent, getBookContentInfo, getBookPage, listFilters, uploadBookFile, uploadBookCover } from '../controllers/booksController.js';
import { authMiddleware, adminOnly, optionalAuth } from '../utils/auth.js';

const router = express.Router();

// Настройки загрузки файлов книг
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.resolve(process.cwd(), 'storage'));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.pdf';
    const base = path.basename(file.originalname, ext).replace(/[^\w\-]+/g, '_');
    cb(null, `book_${req.params.id || Date.now()}_${base}${ext}`);
  }
});

const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const ok = file.mimetype === 'application/epub+zip' || path.extname(file.originalname).toLowerCase() === '.epub';
    if (!ok) {
      return cb(new Error('Только EPUB файлы допустимы'));
    }
    cb(null, true);
  }
});

// Настройки для загрузки обложек
const coverStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.resolve(process.cwd(), 'storage'));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    const base = path.basename(file.originalname, ext).replace(/[^\w\-]+/g, '_');
    cb(null, `cover_${req.params.id || Date.now()}_${base}${ext}`);
  }
});

const uploadCover = multer({
  storage: coverStorage,
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('Только файлы изображений допустимы'));
    }
    cb(null, true);
  },
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB максимум
});

router.get('/', optionalAuth, getBooks);
router.get('/filters/all', listFilters);
router.get('/:id/content/info', optionalAuth, getBookContentInfo);
router.get('/:id/content', optionalAuth, getBookContent);
router.get('/:id/page', optionalAuth, getBookPage);
router.get('/:id', optionalAuth, getBook);

router.post('/', authMiddleware, adminOnly, createBook);
router.put('/:id', authMiddleware, adminOnly, updateBook);
router.delete('/:id', authMiddleware, adminOnly, deleteBook);
router.post('/:id/file', authMiddleware, adminOnly, upload.single('file'), uploadBookFile);
router.post('/:id/cover', authMiddleware, adminOnly, uploadCover.single('cover'), uploadBookCover);

export default router;
