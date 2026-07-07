import Favorite from '../models/Favorite.js';
import Book from '../models/Book.js';
import Author from '../models/Author.js';
import Genre from '../models/Genre.js';
import Publisher from '../models/Publisher.js';
import { Op } from 'sequelize';
import {
  allowedAgeRatingsForRequest,
  isAdminRequest,
  normalizeBookAgeRating
} from '../utils/ageAccess.js';

export async function listFavorites(req, res) {
  try {
    const isAdmin = isAdminRequest(req);
    const allowed = allowedAgeRatingsForRequest(req);
    const favorites = await Favorite.findAll({
      where: { user_id: req.user.user_id },
      include: [{
        model: Book,
        required: !isAdmin,
        ...(isAdmin ? {} : { where: { age_rating: { [Op.in]: allowed } } }),
        include: [Author, { model: Genre, through: { attributes: [] } }, Publisher]
      }],
      order: [['created_at', 'DESC']]
    });
    res.json(favorites.filter((f) => f.Book));
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function addFavorite(req, res) {
  try {
    const { bookId } = req.params;
    const book = await Book.findByPk(bookId);
    if (!book) return res.status(404).json({ message: 'Книга не найдена' });
    if (!isAdminRequest(req)) {
      const allowed = allowedAgeRatingsForRequest(req);
      if (!allowed.includes(normalizeBookAgeRating(book.age_rating))) {
        return res.status(403).json({ message: 'Запрещено по возрасту' });
      }
    }
    const [favorite, created] = await Favorite.findOrCreate({
      where: { user_id: req.user.user_id, book_id: bookId }
    });
    res.status(created ? 201 : 200).json(favorite);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function removeFavorite(req, res) {
  try {
    const { bookId } = req.params;
    await Favorite.destroy({ where: { user_id: req.user.user_id, book_id: bookId } });
    res.json({ message: 'Удалено' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}
