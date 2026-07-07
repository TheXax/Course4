import { sequelize } from '../config/config.js';
import Genre from '../models/Genre.js';

export async function listGenres(req, res) {
  try {
    const genres = await Genre.findAll({ order: [['genre_name', 'ASC']] });
    res.json(genres);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function createGenre(req, res) {
  try {
    const genre = await Genre.create(req.body);
    res.status(201).json(genre);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function updateGenre(req, res) {
  try {
    const { id } = req.params;
    const genre = await Genre.findByPk(id);
    if (!genre) return res.status(404).json({ message: 'Не найдено' });
    await genre.update(req.body);
    res.json(genre);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function deleteGenre(req, res) {
  const transaction = await sequelize.transaction();
  try {
    const { id } = req.params;
    const genre = await Genre.findByPk(id, { transaction });
    if (!genre) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Не найдено' });
    }

    const books = await genre.getBooks({ joinTableAttributes: [], transaction });
    const booksWithSingleGenre = [];

    for (const book of books) {
      const genreCount = await book.countGenres({ transaction });
      if (genreCount === 1) {
        booksWithSingleGenre.push(book.book_id);
      }
    }

    await genre.destroy({ transaction });

    if (booksWithSingleGenre.length) {
      // При необходимости сюда можно добавить дополнительную обработку.
      console.log('Books with undefined genre after deletion:', booksWithSingleGenre);
    }

    await transaction.commit();
    res.json({ message: 'Удалено' });
  } catch (err) {
    console.error(err);
    await transaction.rollback();
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

