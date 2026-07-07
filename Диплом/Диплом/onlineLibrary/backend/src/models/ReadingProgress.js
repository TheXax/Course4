import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const ReadingProgress = sequelize.define('ReadingProgress', {
  progress_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'users', key: 'user_id' }, onDelete: 'CASCADE' },
  book_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'books', key: 'book_id' }, onDelete: 'CASCADE' },
  current_page: { type: DataTypes.INTEGER, defaultValue: 1 },
  total_pages: { type: DataTypes.INTEGER, allowNull: false },
  last_read_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'reading_progress',
  timestamps: false
});

export default ReadingProgress;