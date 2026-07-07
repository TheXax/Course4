import Collection from '../models/Collection.js';
import CollectionBook from '../models/CollectionBook.js';
import Book from '../models/Book.js';
import Author from '../models/Author.js';
import Genre from '../models/Genre.js';
import Publisher from '../models/Publisher.js';
import { Op } from 'sequelize';

const AGE_RATINGS = ['0+', '6+', '12+', '16+', '18+'];
const AGE_RATING_MIN_AGE = {
  '0+': 0,
  '6+': 6,
  '12+': 12,
  '16+': 16,
  '18+': 18
};

function getUserAgeFromRequest(req) {
  const birth = req.user?.birth_date;
  if (!birth) return null;
  const bd = new Date(birth);
  if (Number.isNaN(bd.getTime())) return null;
  const today = new Date();
  let age = today.getFullYear() - bd.getFullYear();
  const m = today.getMonth() - bd.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < bd.getDate())) {
    age--;
  }
  return age;
}

function allowedAgeRatingsForAge(age) {
  if (age == null) return AGE_RATINGS;
  return AGE_RATINGS.filter((tag) => AGE_RATING_MIN_AGE[tag] <= age);
}

export async function listCollections(req, res) {
  try {
    const userId = req.user.user_id;
    const age = getUserAgeFromRequest(req);
    const allowed = allowedAgeRatingsForAge(age);
    const collections = await Collection.findAll({
      where: { user_id: userId },
      include: [{
        model: Book,
        required: false,
        where: { age_rating: { [Op.in]: allowed } },
        through: { attributes: [] },
        include: [Author, { model: Genre, through: { attributes: [] } }, Publisher]
      }]
    });
    res.json(collections);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function getCollection(req, res) {
  try {
    const { collectionId } = req.params;
    const age = getUserAgeFromRequest(req);
    const allowed = allowedAgeRatingsForAge(age);
    const collection = await Collection.findOne({
      where: { collection_id: collectionId, user_id: req.user.user_id },
      include: [{
        model: Book,
        required: false,
        where: { age_rating: { [Op.in]: allowed } },
        through: { attributes: [] },
        include: [Author, { model: Genre, through: { attributes: [] } }, Publisher]
      }]
    });
    if (!collection) return res.status(404).json({ message: 'Не найдено' });
    // Гарантируем, что Books всегда массив
    collection.Books = collection.Books || [];
    res.json(collection);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function createCollection(req, res) {
  try {
    const userId = req.user.user_id;
    const { collection_name } = req.body;
    if (!collection_name) return res.status(400).json({ message: 'Название обязательно' });
    const col = await Collection.create({ user_id: userId, collection_name });
    res.status(201).json(col);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}


export async function addBookToCollection(req, res) {
  try {
    const { collectionId, bookId } = req.params;
    const collection = await Collection.findOne({ where: { collection_id: collectionId, user_id: req.user.user_id }});
    if (!collection) return res.status(404).json({ message: 'Не найдено' });
    await CollectionBook.findOrCreate({ where: { collection_id: collectionId, book_id: bookId }});
    res.json({ message: 'Добавлено' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function removeBookFromCollection(req, res) {
  try {
    const { collectionId, bookId } = req.params;
    const deleted = await CollectionBook.destroy({ where: { collection_id: collectionId, book_id: bookId } });
    if (!deleted) return res.status(404).json({ message: 'Не найдено' });
    res.json({ message: 'Удалено' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function removeCollection(req, res) {
  try {
    const { collectionId } = req.params;
    const collection = await Collection.findOne({ where: { collection_id: collectionId, user_id: req.user.user_id } });
    if (!collection) return res.status(404).json({ message: 'Не найдено' });
    await CollectionBook.destroy({ where: { collection_id: collectionId } });
    await collection.destroy();
    res.json({ message: 'Удалено' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function updateCollection(req, res) {
  try {
    const { collectionId } = req.params;
    const { collection_name } = req.body;
    if (!collection_name) return res.status(400).json({ message: 'Название обязательно' });
    const collection = await Collection.findOne({ where: { collection_id: collectionId, user_id: req.user.user_id } });
    if (!collection) return res.status(404).json({ message: 'Не найдено' });
    collection.collection_name = collection_name;
    await collection.save();
    res.json(collection);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}


