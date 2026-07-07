import Quote from '../models/Quote.js';
import Book from '../models/Book.js';

// Получение всех цитат пользователя
export async function getAllUserQuotes(req, res) {
  try {
    const { user_id } = req.user;

    const quotes = await Quote.findAll({
      where: { user_id },
      include: [{ model: Book, attributes: ['book_id', 'title'] }],
      order: [['created_at', 'DESC']]
    });

    res.json(quotes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

// Получение цитат для конкретной книги
export async function getQuotes(req, res) {
  try {
    const { user_id } = req.user;
    const { bookId } = req.params;

    const quotes = await Quote.findAll({
      where: { user_id, book_id: bookId },
      include: [{ model: Book, attributes: ['book_id', 'title'] }],
      order: [['created_at', 'DESC']]
    });

    res.json(quotes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

// Создание новой цитаты
export async function createQuote(req, res) {
  try {
    console.log('createQuote params:', req.params);
    console.log('createQuote body:', req.body);
    console.log('createQuote user:', req.user);

    const { user_id } = req.user;
    const { bookId } = req.params;
    const { quote_text, color, page } = req.body;
    const safePage = Math.max(1, Number(page) || 1);

    const quote = await Quote.create({
      user_id,
      book_id: bookId,
      quote_text,
      color,
      page: safePage
    });

    res.status(201).json(quote);
  } catch (error) {
    console.error('createQuote error:', error);
    res.status(500).json({ error: error.message });
  }
}

// Удаление цитаты
export async function deleteQuote(req, res) {
  try {
    const { user_id } = req.user;
    const { id } = req.params;

    const quote = await Quote.findOne({ where: { quote_id: id, user_id } });
    if (!quote) {
      return res.status(404).json({ error: 'Цитата не найдена' });
    }

    await quote.destroy();
    res.json({ message: 'Цитата удалена' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}