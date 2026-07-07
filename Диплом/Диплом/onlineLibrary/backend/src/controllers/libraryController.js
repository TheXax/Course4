import Library from '../models/Library.js';
import Read from '../models/Read.js';
import Book from '../models/Book.js';
import Author from '../models/Author.js';
import Publisher from '../models/Publisher.js';
import Genre from '../models/Genre.js';

export async function listLibrary(req, res) {
  try {
    const { user_id } = req.user;
    const entries = await Library.findAll({
      where: { user_id },
      include: [{ model: Book, include: [Author, Publisher, Genre] }]
    });

    const books = entries
      .map((entry) => entry.Book)
      .filter(Boolean);

    res.json(books);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

export async function addToLibrary(req, res) {
  try {
    const { user_id } = req.user;
    const { bookId } = req.params;

    const alreadyRead = await Read.findOne({ where: { user_id, book_id: bookId } });
    if (alreadyRead) {
      return res.status(400).json({ message: 'Эта книга уже в прочитанных' });
    }

    const [entry, created] = await Library.findOrCreate({
      where: { user_id, book_id: bookId },
      defaults: { user_id, book_id: bookId }
    });

    if (!created) {
      return res.status(200).json({ message: 'Книга уже в библиотеке' });
    }

    res.status(201).json({ message: 'Книга добавлена в библиотеку' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

export async function removeFromLibrary(req, res) {
  try {
    const { user_id } = req.user;
    const { bookId } = req.params;

    await Library.destroy({ where: { user_id, book_id: bookId } });
    res.json({ message: 'Книга удалена из библиотеки' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}
