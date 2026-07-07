import { Op } from 'sequelize';
import fs from 'fs/promises';
import path from 'path';
import { createReadStream } from 'fs';
import pdfParse from 'pdf-parse';
import Book from '../models/Book.js';
import Author from '../models/Author.js';
import Publisher from '../models/Publisher.js';
import Genre from '../models/Genre.js';
import { destroyBookWithFiles } from '../utils/bookCleanup.js';
import { fileURLToPath } from 'url';
import Epub from 'epub';
import {
  AGE_RATINGS,
  allowedAgeRatingsForRequest,
  isAdminRequest,
  normalizeBookAgeRating
} from '../utils/ageAccess.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const DEFAULT_PAGE_SIZE = 9000; // символов текста на страницу (приблизительно)
const MAX_PAGE_SIZE = 50000;

// Функция для определения типа файла
function detectFileType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.pdf') return 'pdf';
  if (ext === '.html' || ext === '.htm') return 'html';
  return 'text';
}

// Функция для определения кодировки текстового файла
async function detectEncoding(filePath) {
  const encodings = ['utf-8', 'windows-1251', 'cp866', 'iso-8859-1'];
  
  try {
    const buffer = await fs.readFile(filePath);
    
    // Проверяем BOM для UTF-8
    if (buffer[0] === 0xEF && buffer[1] === 0xBB && buffer[2] === 0xBF) {
      return 'utf-8';
    }
    
    // Пробуем каждую кодировку
    for (const enc of encodings) {
      try {
        const text = buffer.toString(enc);
        // Проверяем, что текст читаемый (нет недопустимых символов замены)
        if (text && !text.includes('\uFFFD') && text.length > 0) {
          // Дополнительная проверка: если много кириллицы, вероятно windows-1251
          if (enc === 'windows-1251' && /[а-яё]/i.test(text)) {
            return enc;
          }
          // Если нет проблемных символов, используем эту кодировку
          if (enc === 'utf-8' || !/[^\x00-\x7F]/.test(text)) {
            return enc;
          }
        }
      } catch (e) {
        continue;
      }
    }
  } catch (e) {
    console.error('Error detecting encoding:', e);
  }
  
  return 'utf-8';
}

// Функция для извлечения текста из PDF
async function extractTextFromPDF(filePath) {
  try {
    const buffer = await fs.readFile(filePath);
    const data = await pdfParse(buffer);
    return data.text || '';
  } catch (err) {
    console.error('Error parsing PDF:', err);
    throw new Error('Failed to parse PDF file');
  }
}

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function normalizeNewlines(text) {
  return String(text).replace(/\r\n/g, '\n').replace(/\r/g, '\n');
}

function textToHtml(text) {
  const normalized = normalizeNewlines(text);
  const escaped = escapeHtml(normalized);
  // Делим на абзацы по пустым строкам, внутри абзаца сохраняем переносы
  const paragraphs = escaped
    .split(/\n{2,}/)
    .map(p => p.trim())
    .filter(Boolean)
    .map(p => `<p>${p.replace(/\n/g, '<br/>')}</p>`);
  if (!paragraphs.length) return '<p></p>';
  return paragraphs.join('');
}

const ALLOWED_HTML_TAGS = new Set([
  'p', 'br', 'strong', 'b', 'em', 'i', 'u', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'ul', 'ol', 'li', 'blockquote', 'div', 'span', 'section', 'article', 'pre', 'code'
]);

/** Ограниченный безопасный HTML для загруженных .html/.htm файлов */
function sanitizeBookHtml(raw) {
  let html = String(raw);
  html = html.replace(/<script[\s\S]*?<\/script>/gi, '');
  html = html.replace(/<style[\s\S]*?<\/style>/gi, '');
  html = html.replace(/<iframe[\s\S]*?<\/iframe>/gi, '');
  html = html.replace(/on\w+\s*=\s*("[^"]*"|'[^']*'|[^\s>]+)/gi, '');
  html = html.replace(/javascript:/gi, '');
  html = html.replace(/<\/?([a-zA-Z0-9]+)\b[^>]*>/g, (full, tagName) => {
    const t = tagName.toLowerCase();
    if (!ALLOWED_HTML_TAGS.has(t)) return '';
    if (full.startsWith('</')) return `</${t}>`;
    if (t === 'br') return '<br/>';
    return `<${t}>`;
  });
  return html.trim() || '<p></p>';
}

function splitHtmlIntoPagesByText(html, pageSize) {
  // html здесь состоит только из <p>...</p> блоков и <br/>, без вложенных тегов от пользователя
  // Режем по границам абзацев, чтобы не ломать структуру
  const parts = html.match(/<p>[\s\S]*?<\/p>/g) || [];
  const pages = [];
  let current = '';
  let currentLen = 0;

  for (const p of parts) {
    // считаем длину текста в абзаце приблизительно, убирая теги
    const textLen = p.replace(/<[^>]+>/g, '').length;
    if (current && currentLen + textLen > pageSize) {
      pages.push(current);
      current = '';
      currentLen = 0;
    }
    current += p;
    currentLen += textLen;
  }
  if (current) pages.push(current);
  return pages.length ? pages : [''];
}

function splitHtmlRoughBySize(html, pageSize) {
  const pages = [];
  let rest = html;
  const textLen = (s) => s.replace(/<[^>]+>/g, '').length;
  while (rest.length) {
    if (textLen(rest) <= pageSize) {
      pages.push(rest);
      break;
    }
    let i = 0;
    let count = 0;
    let inTag = false;
    while (i < rest.length) {
      const ch = rest[i];
      if (ch === '<') inTag = true;
      if (!inTag && ch !== '>') count++;
      if (ch === '>') inTag = false;
      i++;
      if (count >= pageSize) break;
    }
    let slice = rest.slice(0, i);
    const lastGt = slice.lastIndexOf('>');
    if (lastGt > 0) slice = rest.slice(0, lastGt + 1);
    if (!slice.length) slice = rest.slice(0, Math.min(rest.length, pageSize));
    pages.push(slice);
    rest = rest.slice(slice.length);
  }
  return pages.length ? pages : [''];
}

function splitHtmlIntoPagesByBlocks(html, pageSize) {
  const parts = html.split(/(?=<(?:p|div|h[1-6]|ul|ol|blockquote|section|article|pre)\b)/i).filter((p) => p.trim());
  if (parts.length <= 1) {
    return splitHtmlRoughBySize(html, pageSize);
  }
  const pages = [];
  let current = '';
  let currentLen = 0;
  for (const part of parts) {
    const textLen = part.replace(/<[^>]+>/g, '').length;
    if (current && currentLen + textLen > pageSize) {
      pages.push(current);
      current = '';
      currentLen = 0;
    }
    current += part;
    currentLen += textLen;
  }
  if (current) pages.push(current);
  return pages.length ? pages : ['<p></p>'];
}

function splitHtmlIntoPagesUnified(html, pageSize) {
  const hasOurParagraphs = /<p>[\s\S]*?<\/p>/i.test(html);
  if (hasOurParagraphs) {
    return splitHtmlIntoPagesByText(html, pageSize);
  }
  return splitHtmlIntoPagesByBlocks(html, pageSize);
}

const bookPagesCache = new Map();

function clearBookPagesCache(bookId) {
  for (const key of bookPagesCache.keys()) {
    if (key.startsWith(`${bookId}:`)) bookPagesCache.delete(key);
  }
}

async function getBookPages(book, pageSize) {
  const cacheKey = `${book.book_id}:${pageSize}`;

  if (book.content_html) {
    const sourceKey = `html:${book.content_html.length}`;
    const cached = bookPagesCache.get(cacheKey);
    if (cached && cached.sourceKey === sourceKey) {
      return { pages: cached.pages, totalPages: cached.pages.length, fileType: cached.fileType || 'epub' };
    }
    const pages = splitHtmlIntoPagesUnified(book.content_html, pageSize);
    bookPagesCache.set(cacheKey, { pages, totalChars: book.content_html.length, fileType: 'epub', sourceKey });
    return { pages, totalPages: pages.length, fileType: 'epub' };
  }

  if (!book.book_file) {
    return { pages: [''], totalPages: 1, fileType: 'text' };
  }

  const built = await buildBookPages(book, pageSize);
  return { pages: built.pages, totalPages: built.pages.length, fileType: built.fileType };
}

async function buildBookPages(book, pageSize) {
  const filePath = path.resolve(process.cwd(), book.book_file);
  const stats = await fs.stat(filePath);
  const fileType = detectFileType(filePath);

  const cacheKey = `${book.book_id}:${pageSize}`;
  const cached = bookPagesCache.get(cacheKey);
  if (cached && cached.mtimeMs === stats.mtimeMs) return cached;

  let fullText = '';
  let html = '';
  if (fileType === 'pdf') {
    fullText = await extractTextFromPDF(filePath);
    html = textToHtml(fullText);
  } else if (fileType === 'html') {
    const encoding = await detectEncoding(filePath);
    const buffer = await fs.readFile(filePath);
    fullText = buffer.toString(encoding);
    html = sanitizeBookHtml(fullText);
  } else {
    const encoding = await detectEncoding(filePath);
    const buffer = await fs.readFile(filePath);
    fullText = buffer.toString(encoding);
    html = textToHtml(fullText);
  }

  const pages = splitHtmlIntoPagesUnified(html, pageSize);
  const payload = { mtimeMs: stats.mtimeMs, pages, totalChars: fullText.length, fileType };
  bookPagesCache.set(cacheKey, payload);
  return payload;
}

/**
 * GET /api/books
 * ?genre_id=&author_id=&search=
 */
export async function getBooks(req, res) {
  try {
    const { genre_id, author_id, search, age_rating, limit = 1000, offset = 0 } = req.query;
    const where = {};

    if (author_id) where.author_id = author_id;

    const isAdmin = isAdminRequest(req);
    if (!isAdmin) {
      const allowedRatings = allowedAgeRatingsForRequest(req);
      if (age_rating) {
        if (!AGE_RATINGS.includes(age_rating)) {
          return res.status(400).json({ message: 'Неверный возрастной рейтинг' });
        }
        if (!allowedRatings.includes(age_rating)) {
          return res.json({ total: 0, items: [] });
        }
        where.age_rating = age_rating;
      } else {
        where.age_rating = { [Op.in]: allowedRatings };
      }
    } else if (age_rating) {
      if (!AGE_RATINGS.includes(age_rating)) {
        return res.status(400).json({ message: 'Неверный возрастной рейтинг' });
      }
      where.age_rating = age_rating;
    }
    if (search) {
      where[Op.or] = [
        { title: { [Op.iLike]: `%${search}%` } },
        { description: { [Op.iLike]: `%${search}%` } }
      ];
    }

    const genreInclude = genre_id ? [{
      model: Genre,
      through: { attributes: [] },
      where: { genre_id: Number(genre_id) },
      required: true
    }] : [{
      model: Genre,
      through: { attributes: [] },
      required: false
    }];

    const books = await Book.findAndCountAll({
      where,
      include: [Author, Publisher, ...genreInclude],
      order: [['created_at', 'DESC']],
      limit: Number(limit),
      offset: Number(offset)
    });

    res.json({ total: books.count, items: books.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

/**
 * GET /api/books/:id
 */
export async function getBook(req, res) {
  try {
    const { id } = req.params;

    const book = await Book.findByPk(id, {
      include: [Author, Publisher, { model: Genre, through: { attributes: [] } }]
    });

    if (!book) return res.status(404).json({ message: 'Книга не найдена' });

    if (!isAdminRequest(req)) {
      const allowed = allowedAgeRatingsForRequest(req);
      if (!allowed.includes(normalizeBookAgeRating(book.age_rating))) {
        return res.status(404).json({ message: 'Книга не найдена' });
      }
    }

    res.json(book);

  } catch (err) {
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

function normalizeGenreIds(body) {
  // Принимаем либо genre_ids: number[], либо genre_id: number (для обратной совместимости)
  if (Array.isArray(body.genre_ids)) return body.genre_ids;
  if (body.genre_id !== undefined && body.genre_id !== null && body.genre_id !== '') return [body.genre_id];
  return [];
}

function normalizeIsbn(value) {
  return String(value || '').trim();
}

function validateIsbnOrFail(rawValue) {
  const isbn = normalizeIsbn(rawValue);
  if (!isbn) {
    const err = new Error('Введите ISBN в формате ХХХ-Х-ХХ-ХХХХХХ-Х');
    err.statusCode = 400;
    throw err;
  }
  if (!/^\d{3}-\d-\d{2}-\d{6}-\d$/.test(isbn)) {
    const err = new Error('Введите ISBN в формате ХХХ-Х-ХХ-ХХХХХХ-Х');
    err.statusCode = 400;
    throw err;
  }
  return isbn;
}

async function validateGenresOrFail(rawGenreIds) {
  const ids = rawGenreIds
    .map(v => Number(v))
    .filter(v => Number.isFinite(v) && v > 0);

  const unique = [...new Set(ids)];
  if (!unique.length) return [];

  const genres = await Genre.findAll({ where: { genre_id: unique } });
  if (genres.length !== unique.length) {
    const found = new Set(genres.map(g => g.genre_id));
    const missing = unique.filter(id => !found.has(id));
    const msg = missing.length === 1
      ? `Жанр с ID ${missing[0]} не найден`
      : `Жанры не найдены: ${missing.join(', ')}`;
    const err = new Error(msg);
    err.statusCode = 400;
    throw err;
  }
  return unique;
}

/**
 * POST /api/books (admin)
 */
export async function createBook(req, res) {
  try {
    const data = req.body;
    
    // Валидация существования автора, издателя и жанра
    if (data.author_id) {
      const authorId = parseInt(data.author_id);
      if (isNaN(authorId) || authorId <= 0) {
        return res.status(400).json({ message: 'Невалидный ID автора' });
      }
      const author = await Author.findByPk(authorId);
      if (!author) {
        return res.status(400).json({ message: 'Автор с указанным ID не найден' });
      }
      data.author_id = authorId;
    }
    
    if (data.publisher_id) {
      const publisherId = parseInt(data.publisher_id);
      if (isNaN(publisherId) || publisherId <= 0) {
        return res.status(400).json({ message: 'Невалидный ID издательства' });
      }
      const publisher = await Publisher.findByPk(publisherId);
      if (!publisher) {
        return res.status(400).json({ message: 'Издательство с указанным ID не найдено' });
      }
      data.publisher_id = publisherId;
    }
    
    const genreIds = await validateGenresOrFail(normalizeGenreIds(data));
    if (genreIds.length === 0) {
      return res.status(400).json({ message: 'Книга должна иметь хотя бы один жанр' });
    }
    delete data.genre_id;
    delete data.genre_ids;

    if (data.age_rating != null && data.age_rating !== '') {
      if (!AGE_RATINGS.includes(data.age_rating)) {
        return res.status(400).json({ message: 'Неверный возрастной рейтинг' });
      }
    } else {
      data.age_rating = '0+';
    }

    try {
      data.isbn = validateIsbnOrFail(data.isbn);
    } catch (isbnError) {
      return res.status(isbnError.statusCode || 400).json({ message: isbnError.message });
    }
    const existingBook = await Book.findOne({ where: { isbn: data.isbn } });
    if (existingBook) {
      return res.status(409).json({ message: 'Книга с таким ISBN уже существует' });
    }
    
    // Валидация года
    if (data.year) {
      const year = parseInt(data.year);
      const currentYear = new Date().getFullYear();
      if (isNaN(year) || year < 1000 || year > currentYear) {
        return res.status(400).json({ message: `Год должен быть от 1455 до ${currentYear}` });
      }
      data.year = year;
    }
    
    const book = await Book.create(data);
    if (genreIds.length) await book.setGenres(genreIds);

    const created = await Book.findByPk(book.book_id, {
      include: [Author, Publisher, { model: Genre, through: { attributes: [] } }]
    });
    res.status(201).json(created);

  } catch (err) {
    console.error(err);
    if (err.statusCode) return res.status(err.statusCode).json({ message: err.message });
    if (err.name === 'SequelizeValidationError') {
      return res.status(400).json({ message: err.errors[0]?.message || 'Ошибка валидации' });
    }
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

/**
 * PUT /api/books/:id (admin)
 */
export async function updateBook(req, res) {
  try {
    const { id } = req.params;
    const data = req.body;

    const book = await Book.findByPk(id);
    if (!book) return res.status(404).json({ message: 'Книга не найдена' });

    // Валидация существования автора, издателя и жанра
    if (data.author_id !== undefined) {
      if (data.author_id === '' || data.author_id === null) {
        data.author_id = null;
      } else {
        const authorId = parseInt(data.author_id);
        if (isNaN(authorId) || authorId <= 0) {
          return res.status(400).json({ message: 'Невалидный ID автора' });
        }
        const author = await Author.findByPk(authorId);
        if (!author) {
          return res.status(400).json({ message: 'Автор с указанным ID не найден' });
        }
        data.author_id = authorId;
      }
    }
    
    if (data.publisher_id !== undefined) {
      if (data.publisher_id === '' || data.publisher_id === null) {
        data.publisher_id = null;
      } else {
        const publisherId = parseInt(data.publisher_id);
        if (isNaN(publisherId) || publisherId <= 0) {
          return res.status(400).json({ message: 'Невалидный ID издательства' });
        }
        const publisher = await Publisher.findByPk(publisherId);
        if (!publisher) {
          return res.status(400).json({ message: 'Издательство с указанным ID не найдено' });
        }
        data.publisher_id = publisherId;
      }
    }
    
    const hasGenreChange = data.genre_ids !== undefined || data.genre_id !== undefined;
    const genreIds = hasGenreChange ? await validateGenresOrFail(normalizeGenreIds(data)) : null;
    if (hasGenreChange && genreIds.length === 0) {
      return res.status(400).json({ message: 'Книга должна иметь хотя бы один жанр' });
    }
    if (hasGenreChange) {
      delete data.genre_id;
      delete data.genre_ids;
    }

    if (data.age_rating !== undefined) {
      if (data.age_rating === '' || data.age_rating === null) {
        data.age_rating = '0+';
      } else if (!AGE_RATINGS.includes(data.age_rating)) {
        return res.status(400).json({ message: 'Неверный возрастной рейтинг' });
      }
    }

    if (data.isbn !== undefined) {
      try {
        data.isbn = validateIsbnOrFail(data.isbn);
      } catch (isbnError) {
        return res.status(isbnError.statusCode || 400).json({ message: isbnError.message });
      }
      const existingBook = await Book.findOne({
        where: {
          isbn: data.isbn,
          book_id: { [Op.ne]: book.book_id }
        }
      });
      if (existingBook) {
        return res.status(409).json({ message: 'Книга с таким ISBN уже существует' });
      }
    }
    
    // Валидация года
    if (data.year !== undefined) {
      if (data.year === '' || data.year === null) {
        data.year = null;
      } else {
        const year = parseInt(data.year);
        const currentYear = new Date().getFullYear();
        if (isNaN(year) || year < 1000 || year > currentYear) {
          return res.status(400).json({ message: `Год должен быть от 1455 до ${currentYear}` });
        }
        data.year = year;
      }
    }

    const currentGenreCount = await book.countGenres();
    if (currentGenreCount === 0 && !hasGenreChange) {
      return res.status(403).json({ message: 'Книга без жанра не может быть отредактирована' });
    }

    await book.update(data);
    if (hasGenreChange) await book.setGenres(genreIds);

    const updated = await Book.findByPk(book.book_id, {
      include: [Author, Publisher, { model: Genre, through: { attributes: [] } }]
    });
    res.json(updated);

  } catch (err) {
    console.error(err);
    if (err.statusCode) return res.status(err.statusCode).json({ message: err.message });
    if (err.name === 'SequelizeValidationError') {
      return res.status(400).json({ message: err.errors[0]?.message || 'Ошибка валидации' });
    }
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

/**
 * DELETE /api/books/:id (admin)
 */
export async function deleteBook(req, res) {
  try {
    const { id } = req.params;

    const book = await Book.findByPk(id);
    if (!book) return res.status(404).json({ message: 'Книга не найдена' });

    await destroyBookWithFiles(book);
    res.json({ message: 'Удалено' });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

/**
 * GET /api/books/:id/content
 * Возвращает HTML первой страницы книги
 */
export async function getBookContent(req, res) {
  try {
    const { id } = req.params;
    const book = await Book.findByPk(id);
    if (!book) return res.status(404).json({ message: 'Книга не найдена' });

    if (!isAdminRequest(req)) {
      const allowed = allowedAgeRatingsForRequest(req);
      if (!allowed.includes(normalizeBookAgeRating(book.age_rating))) {
        return res.status(403).json({ message: 'Запрещено по возрасту' });
      }
    }

    const { pages, totalPages } = await getBookPages(book, DEFAULT_PAGE_SIZE);
    if (!pages.length || !pages[0]) {
      return res.status(404).json({ message: 'Книжные данные не найдены' });
    }

    res.json({
      content: pages[0],
      total_pages: totalPages
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message || 'Ошибка сервера' });
  }
}

/**
 * GET /api/books/:id/page?page=1&pageSize=9000
 */
export async function getBookPage(req, res) {
  try {
    const { id } = req.params;
    const page = Math.max(1, Number(req.query.page || 1));
    const pageSize = Math.min(
      MAX_PAGE_SIZE,
      Math.max(500, Number(req.query.pageSize || DEFAULT_PAGE_SIZE))
    );

    const book = await Book.findByPk(id);
    if (!book) return res.status(404).json({ message: 'Книга не найдена' });

    if (!isAdminRequest(req)) {
      const allowed = allowedAgeRatingsForRequest(req);
      if (!allowed.includes(normalizeBookAgeRating(book.age_rating))) {
        return res.status(403).json({ message: 'Запрещено по возрасту' });
      }
    }

    const { pages, totalPages } = await getBookPages(book, pageSize);
    if (!pages.length) {
      return res.status(404).json({ message: 'Книжные данные не найдены' });
    }

    const safePage = Math.min(page, totalPages);
    res.json({
      page: safePage,
      totalPages,
      html: pages[safePage - 1] || ''
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message || 'Ошибка сервера' });
  }
}

/**
 * GET /api/books/:id/content/info
 * Возвращает информацию о структуре книги (количество глав, etc.)
 */
export async function getBookContentInfo(req, res) {
  try {
    const { id } = req.params;
    const book = await Book.findByPk(id);
    if (!book) return res.status(404).json({ message: 'Книга не найдена' });

    if (!isAdminRequest(req)) {
      const allowed = allowedAgeRatingsForRequest(req);
      if (!allowed.includes(normalizeBookAgeRating(book.age_rating))) {
        return res.status(403).json({ message: 'Запрещено по возрасту' });
      }
    }

    const pageSize = Math.min(
      MAX_PAGE_SIZE,
      Math.max(500, Number(req.query.pageSize || DEFAULT_PAGE_SIZE))
    );
    const { totalPages, fileType } = await getBookPages(book, pageSize);

    res.json({
      total_pages: totalPages,
      file_format: fileType || (book.book_file ? detectFileType(path.resolve(process.cwd(), book.book_file)) : 'text')
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

function cleanEpubSectionHtml(sectionHtml) {
  let cleanHtml = sectionHtml
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/\s+style\s*=\s*["'][^"']*["']/gi, '')
    .replace(/\s+class\s*=\s*["'][^"']*["']/gi, '')
    .replace(/<font[^>]*>[\s\S]*?<\/font>/gi, '')
    .replace(/<span[^>]*>([\s\S]*?)<\/span>/gi, '$1')
    .replace(/font-weight:\s*bold[^;]*;?/gi, '');

  return cleanHtml.replace(/<\/?(?!p|h[1-6]|img|blockquote|br)[^>]*>/gi, '');
}

async function processEpubImages(epub, bookId, cleanHtml) {
  const imgRegex = /<img[^>]+src\s*=\s*["']([^"']+)["'][^>]*>/gi;
  let match;
  const uploadsDir = path.join(process.cwd(), 'storage', 'books', bookId.toString());
  await fs.mkdir(uploadsDir, { recursive: true });
  let result = cleanHtml;

  while ((match = imgRegex.exec(cleanHtml)) !== null) {
    const imgSrc = match[1];
    if (!imgSrc.startsWith('http')) {
      const imgBuffer = await new Promise((resolveImg, rejectImg) => {
        epub.getImage(imgSrc, (err, data, mimeType) => {
          if (err) rejectImg(err);
          else resolveImg({ data, mimeType });
        });
      });

      const ext = imgBuffer.mimeType.split('/')[1] || 'png';
      const imgName = `img_${Date.now()}_${Math.random().toString(36).substr(2, 9)}.${ext}`;
      const imgPath = path.join(uploadsDir, imgName);
      await fs.writeFile(imgPath, imgBuffer.data);

      const newSrc = `/storage/books/${bookId}/${imgName}`;
      result = result.replace(match[0], match[0].replace(imgSrc, newSrc));
    }
  }

  return result;
}

// Парсинг EPUB: единый HTML текста книги в books.content_html
async function parseAndSaveEpub(bookId, filePath) {
  return new Promise((resolve, reject) => {
    const epub = new Epub(filePath);

    epub.on('error', (err) => {
      console.error('EPUB parse error:', err);
      reject(err);
    });

    epub.on('end', async () => {
      try {
        const sections = [];
        for (let i = 0; i < epub.flow.length; i++) {
          const item = epub.flow[i];
          if (item.level !== 0) continue;

          const sectionHtml = await new Promise((resolveSection, rejectSection) => {
            epub.getChapter(item.id, (err, text) => {
              if (err) rejectSection(err);
              else resolveSection(text);
            });
          });

          let cleanHtml = cleanEpubSectionHtml(sectionHtml);
          cleanHtml = await processEpubImages(epub, bookId, cleanHtml);
          if (cleanHtml.trim()) sections.push(cleanHtml);
        }

        const fullHtml = sections.join('');
        const book = await Book.findByPk(bookId);
        if (book) {
          book.content_html = fullHtml || '<p></p>';
          await book.save();
          clearBookPagesCache(bookId);
        }

        const { totalPages } = book
          ? await getBookPages(book, DEFAULT_PAGE_SIZE)
          : { totalPages: 1 };

        console.log(`Saved book ${bookId} content (${totalPages} pages)`);
        resolve(totalPages);
      } catch (err) {
        reject(err);
      }
    });

    epub.parse();
  });
}

export async function uploadBookFile(req, res) {
  try {
    const { id } = req.params;
    const book = await Book.findByPk(id);
    if (!book) return res.status(404).json({ message: 'Книга не найдена' });
    if (!req.file) return res.status(400).json({ message: 'Файл не загружен' });

    // Сохраняем относительный путь
    const relativePath = `storage/${req.file.filename}`;
    book.book_file = relativePath;
    await book.save();

    const fullPath = path.resolve(process.cwd(), relativePath);
    const totalPages = await parseAndSaveEpub(id, fullPath);

    res.json({
      message: 'Файл загружен и обработан',
      book_file: relativePath,
      file_path: relativePath,
      total_pages: totalPages
    });
  } catch (err) {
    console.error('Ошибка загрузки:', err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

/**
 * POST /api/books/:id/cover (admin)
 * Загружает обложку книги
 */
export async function uploadBookCover(req, res) {
  try {
    const { id } = req.params;
    const book = await Book.findByPk(id);
    if (!book) return res.status(404).json({ message: 'Книга не найдена' });
    if (!req.file) return res.status(400).json({ message: 'Обложка не загружена' });

    // Сохраняем относительный путь к обложке
    const relativePath = `storage/${req.file.filename}`;
    book.cover_image = relativePath;
    await book.save();

    res.json({ message: 'Обоожка загружена', cover_image: relativePath });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function listFilters(req, res) {
  try {
    const [authors, publishers, genres] = await Promise.all([
      Author.findAll({ order: [['author_name', 'ASC']] }),
      Publisher.findAll({ order: [['publisher_name', 'ASC']] }),
      Genre.findAll({ order: [['genre_name', 'ASC']] })
    ]);
    res.json({ authors, publishers, genres });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}
