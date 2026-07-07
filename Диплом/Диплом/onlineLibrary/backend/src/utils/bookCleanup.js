import fs from 'fs/promises';
import path from 'path';

async function safeUnlink(filePath) {
  try {
    await fs.unlink(filePath);
  } catch (err) {
    if (err.code !== 'ENOENT') {
      console.error(`Failed to delete file ${filePath}:`, err);
    }
  }
}

async function safeRemoveDir(dirPath) {
  try {
    await fs.rm(dirPath, { recursive: true, force: true });
  } catch (err) {
    if (err.code !== 'ENOENT') {
      console.error(`Failed to remove directory ${dirPath}:`, err);
    }
  }
}

export async function removeBookFiles(book) {
  if (!book) return;
  if (book.book_file) {
    const filePath = path.resolve(process.cwd(), book.book_file);
    await safeUnlink(filePath);
  }
  if (book.cover_image) {
    const coverPath = path.resolve(process.cwd(), book.cover_image);
    await safeUnlink(coverPath);
  }

  const parsedImagesDir = path.resolve(process.cwd(), 'storage', 'books', String(book.book_id));
  await safeRemoveDir(parsedImagesDir);
}

export async function destroyBookWithFiles(book, options = {}) {
  try {
    await removeBookFiles(book);
  } catch (err) {
    console.error(`Error removing files for book ${book.book_id}:`, err);
  }
  return book.destroy(options);
}
