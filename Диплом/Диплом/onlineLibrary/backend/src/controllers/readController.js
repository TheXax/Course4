import Read from '../models/Read.js';
import Library from '../models/Library.js';
import Book from '../models/Book.js';
import Author from '../models/Author.js';
import Publisher from '../models/Publisher.js';
import Genre from '../models/Genre.js';

export async function listRead(req, res) {
  try {
    const { user_id } = req.user;
    const entries = await Read.findAll({
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

export async function addToRead(req, res) {
  try {
    const { user_id } = req.user;
    const { bookId } = req.params;

    const [entry, created] = await Read.findOrCreate({
      where: { user_id, book_id: bookId },
      defaults: { user_id, book_id: bookId }
    });

    await Library.destroy({ where: { user_id, book_id: bookId } });

    if (!created) {
      return res.status(200).json({ message: 'Книга уже отмечена как прочитанная' });
    }

    res.status(201).json({ message: 'Книга добавлена в прочитанное' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

export async function removeFromRead(req, res) {
  try {
    const { user_id } = req.user;
    const { bookId } = req.params;

    await Read.destroy({ where: { user_id, book_id: bookId } });
    res.json({ message: 'Книга удалена из прочитанного' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}
