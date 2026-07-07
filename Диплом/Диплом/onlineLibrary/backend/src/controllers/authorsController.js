import { sequelize } from '../config/config.js';
import Author from '../models/Author.js';
import Book from '../models/Book.js';
import { destroyBookWithFiles } from '../utils/bookCleanup.js';

export async function listAuthors(req, res) {
  try {
    const authors = await Author.findAll({ order: [['author_name', 'ASC']] });
    res.json(authors);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function createAuthor(req, res) {
  try {
    const author = await Author.create(req.body);
    res.status(201).json(author);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function updateAuthor(req, res) {
  try {
    const { id } = req.params;
    const author = await Author.findByPk(id);
    if (!author) return res.status(404).json({ message: 'Не найдено' });
    await author.update(req.body);
    res.json(author);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function deleteAuthor(req, res) {
  const transaction = await sequelize.transaction();
  try {
    const { id } = req.params;
    const author = await Author.findByPk(id, { transaction });
    if (!author) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Не найдено' });
    }

    const books = await Book.findAll({ where: { author_id: id }, transaction });
    for (const book of books) {
      await destroyBookWithFiles(book, { transaction });
    }

    await author.destroy({ transaction });
    await transaction.commit();
    res.json({ message: 'Удалено' });
  } catch (err) {
    console.error(err);
    await transaction.rollback();
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

