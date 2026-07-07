import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
dotenv.config();

import authRoutes from './routes/auth.js';
import booksRoutes from './routes/books.js';
import collectionsRoutes from './routes/collections.js';
import commentsRoutes from './routes/comments.js';
import adminRoutes from './routes/admin.js';
import profileRoutes from './routes/profile.js';
import favoritesRoutes from './routes/favorites.js';
import authorsRoutes from './routes/authors.js';
import publishersRoutes from './routes/publishers.js';
import genresRoutes from './routes/genres.js';
import readingRoutes from './routes/reading.js';
import libraryRoutes from './routes/library.js';
import readRoutes from './routes/read.js';
import quotesRoutes from './routes/quotes.js';
import notesRoutes from './routes/notes.js';

import initDb from './initDb.js';
import './models/associations.js';

const app = express();
app.use(cors());
app.use(express.json());

const storageDir = path.resolve(process.cwd(), 'storage');
if (!fs.existsSync(storageDir)) {
  fs.mkdirSync(storageDir, { recursive: true });
}
app.use('/storage', express.static(storageDir));

app.get('/', (req, res) => res.send('API работает!'));

app.use('/api/auth', authRoutes);
app.use('/api/books', booksRoutes);
app.use('/api/collections', collectionsRoutes);
app.use('/api/comments', commentsRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/favorites', favoritesRoutes);
app.use('/api/authors', authorsRoutes);
app.use('/api/publishers', publishersRoutes);
app.use('/api/genres', genresRoutes);
app.use('/api/reading', readingRoutes);
app.use('/api/library', libraryRoutes);
app.use('/api/read', readRoutes);
app.use('/api/quotes', quotesRoutes);
app.use('/api/notes', notesRoutes);

const PORT = process.env.PORT || 4000;
app.listen(PORT, async () => {
  console.log(`Server started on ${PORT}`);
  try { await initDb(); } catch(e) { console.error(e); }
});
