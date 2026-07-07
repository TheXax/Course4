import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Note = sequelize.define('Note', {
  note_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'users', key: 'user_id' }, onDelete: 'CASCADE' },
  book_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'books', key: 'book_id' }, onDelete: 'CASCADE' },
  selection_text: { type: DataTypes.TEXT, allowNull: false },
  user_text: { type: DataTypes.TEXT },
  color: { type: DataTypes.TEXT, allowNull: true, defaultValue: '#f5ae0b' },
  page: { type: DataTypes.INTEGER, allowNull: false },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'notes',
  timestamps: false
});

export default Note;