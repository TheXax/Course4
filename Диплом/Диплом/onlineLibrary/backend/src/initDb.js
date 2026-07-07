import { sequelize } from './config/config.js';
import Role from './models/Role.js';
import User from './models/User.js';
import Book from './models/Book.js';
import Author from './models/Author.js';
import Publisher from './models/Publisher.js';
import Genre from './models/Genre.js';
import BookGenre from './models/BookGenre.js';
import Collection from './models/Collection.js';
import Comment from './models/Comment.js';
import Favorite from './models/Favorite.js';
import ReadingProgress from './models/ReadingProgress.js';
import Library from './models/Library.js';
import Read from './models/Read.js';
import Quote from './models/Quote.js';
import Note from './models/Note.js';
import './models/associations.js';

// Функция для ожидания подключения к БД с повторными попытками
async function waitForDb(maxRetries = 10, delay = 2000) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      await sequelize.authenticate();
      console.log('Database connection established');
      return true;
    } catch (err) {
      console.log(`Waiting for database... (attempt ${i + 1}/${maxRetries})`);
      if (i < maxRetries - 1) {
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        throw new Error('Не удалось подключиться к базе данных после нескольких попыток');
      }
    }
  }
}

export default async function initDb() {
  try {
    // Ждем подключения к БД
    await waitForDb();
    
    const syncForce = process.env.DB_SYNC_FORCE === 'true';
    const syncAlter = process.env.DB_SYNC_ALTER === 'true';

    if (syncForce) {
      console.warn('WARNING: DB_SYNC_FORCE=true will recreate all tables and delete data.');
    }

    // Синхронизируем модели: по умолчанию только создание отсутствующих таблиц
    console.log('Synchronizing database models...');
    await sequelize.sync({ force: syncForce, alter: syncAlter });
    
    // Seed ролей: выполняется идемпотентно, только если записи отсутствуют
    const roles = [{ role_id: 1, role_name: 'admin' }, { role_id: 2, role_name: 'user' }];
    for (const r of roles) {
      const found = await Role.findByPk(r.role_id);
      if (!found) {
        await Role.create(r);
        console.log(`Created role: ${r.role_name}`);
      }
    }
    
    console.log('Database initialized successfully');
  } catch (err) {
    console.error('DB init error:', err);
    throw err;
  }
}
