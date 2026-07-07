import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Book = sequelize.define('Book', {
  book_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  title: { type: DataTypes.STRING(200), allowNull: false },
  isbn: { type: DataTypes.STRING(20), allowNull: false, unique: true, validate: { notEmpty: true } },
  author_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: { model: 'authors', key: 'author_id' },
    onDelete: 'SET NULL',
    onUpdate: 'CASCADE'
  },
  publisher_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: { model: 'publishers', key: 'publisher_id' },
    onDelete: 'SET NULL',
    onUpdate: 'CASCADE'
  },
  description: { type: DataTypes.TEXT },
  year: { type: DataTypes.INTEGER },
  age_rating: { type: DataTypes.STRING(10) },
  cover_image: { type: DataTypes.STRING(255) },
  book_file: { type: DataTypes.STRING(255) },
  content_html: { type: DataTypes.TEXT },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'books',
  timestamps: false
});

export default Book;
