import Note from '../models/Note.js';
import Book from '../models/Book.js';

// Получение всех заметок пользователя
export async function getAllUserNotes(req, res) {
  try {
    const { user_id } = req.user;

    const notes = await Note.findAll({
      where: { user_id },
      include: [{ model: Book, attributes: ['book_id', 'title'] }],
      order: [['created_at', 'DESC']]
    });

    res.json(notes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

// Получение заметок для конкретной книги
export async function getNotes(req, res) {
  try {
    const { user_id } = req.user;
    const { bookId } = req.params;

    const notes = await Note.findAll({
      where: { user_id, book_id: bookId },
      include: [{ model: Book, attributes: ['book_id', 'title'] }],
      order: [['created_at', 'DESC']]
    });

    res.json(notes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

// Создание новой заметки
export async function createNote(req, res) {
  try {
    console.log('createNote params:', req.params);
    console.log('createNote body:', req.body);
    console.log('createNote user:', req.user);

    const { user_id } = req.user;
    const { bookId } = req.params;
    const { selection_text, user_text, page, color } = req.body;
    const safePage = Math.max(1, Number(page) || 1);

    const note = await Note.create({
      user_id,
      book_id: bookId,
      selection_text,
      user_text,
      color,
      page: safePage
    });

    res.status(201).json(note);
  } catch (error) {
    console.error('createNote error:', error);
    res.status(500).json({ error: error.message });
  }
}

// Редактирование заметки
export async function updateNote(req, res) {
  try {
    const { user_id } = req.user;
    const { id } = req.params;
    const { selection_text, user_text } = req.body;

    const note = await Note.findOne({ where: { note_id: id, user_id } });
    if (!note) {
      return res.status(404).json({ error: 'Заметка не найдена' });
    }

    note.selection_text = selection_text;
    note.user_text = user_text;
    await note.save();

    res.json(note);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

// Удаление заметки
export async function deleteNote(req, res) {
  try {
    const { user_id } = req.user;
    const { id } = req.params;

    const note = await Note.findOne({ where: { note_id: id, user_id } });
    if (!note) {
      return res.status(404).json({ error: 'Заметка не найдена' });
    }

    await note.destroy();
    res.json({ message: 'Заметка удалена' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}