import { sequelize } from '../config/config.js';
import Publisher from '../models/Publisher.js';
import Book from '../models/Book.js';
import { destroyBookWithFiles } from '../utils/bookCleanup.js';

export async function listPublishers(req, res) {
  try {
    const publishers = await Publisher.findAll({ order: [['publisher_name', 'ASC']] });
    res.json(publishers);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function createPublisher(req, res) {
  try {
    const publisher = await Publisher.create(req.body);
    res.status(201).json(publisher);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function updatePublisher(req, res) {
  try {
    const { id } = req.params;
    const publisher = await Publisher.findByPk(id);
    if (!publisher) return res.status(404).json({ message: 'Не найдено' });
    await publisher.update(req.body);
    res.json(publisher);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function deletePublisher(req, res) {
  const transaction = await sequelize.transaction();
  try {
    const { id } = req.params;
    const publisher = await Publisher.findByPk(id, { transaction });
    if (!publisher) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Не найдено' });
    }

    const books = await Book.findAll({ where: { publisher_id: id }, transaction });
    for (const book of books) {
      await destroyBookWithFiles(book, { transaction });
    }

    await publisher.destroy({ transaction });
    await transaction.commit();
    res.json({ message: 'Удалено' });
  } catch (err) {
    console.error(err);
    await transaction.rollback();
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

