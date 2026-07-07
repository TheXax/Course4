import { sequelize } from '../config/config.js';
import ReadingProgress from '../models/ReadingProgress.js';
import Library from '../models/Library.js';
import Read from '../models/Read.js';

//Получение прогресса чтения пользователя и книги
export async function getReadingProgress(req, res) {
  try {
    const { user_id } = req.user;
    const { bookId } = req.params;

    const progress = await ReadingProgress.findOne({
      where: { user_id, book_id: bookId }
    });

    if (!progress) {
      return res.json({ current_page: 1, total_pages: 1 }); //дефолт
    }

    res.json({
      current_page: progress.current_page,
      total_pages: progress.total_pages,
      last_read_at: progress.last_read_at
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

//обновление прогресса чтения и перемещение в прочитанное
export async function updateReadingProgress(req, res) {
  try {
    const { user_id } = req.user;
    const { bookId } = req.params;
    const current_page = Number(req.body.current_page);
    const total_pages = Number(req.body.total_pages);

    if (!Number.isFinite(current_page) || !Number.isFinite(total_pages) || current_page < 1 || total_pages < 1) {
      return res.status(400).json({ message: 'Требуется current_page и total_pages' });
    }

    const progress = await sequelize.transaction(async (transaction) => {
      const [row] = await ReadingProgress.upsert({
        user_id,
        book_id: bookId,
        current_page,
        total_pages,
        last_read_at: new Date()
      }, { transaction });

      const isFinished = current_page >= total_pages;

      if (isFinished) {
        await Library.destroy({ where: { user_id, book_id: bookId }, transaction });
        await Read.findOrCreate({
          where: { user_id, book_id: bookId },
          defaults: { user_id, book_id: bookId },
          transaction
        });
      } else {
        await Read.destroy({ where: { user_id, book_id: bookId }, transaction });
      }

      return row;
    });

    res.json({ message: 'Прогресс обновлен', progress });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}