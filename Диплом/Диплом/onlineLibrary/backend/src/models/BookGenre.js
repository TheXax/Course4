import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const BookGenre = sequelize.define('BookGenre', {
  book_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    references: { model: 'books', key: 'book_id' },
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE'
  },
  genre_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    references: { model: 'genres', key: 'genre_id' },
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE'
  }
}, {
  tableName: 'book_genres',
  timestamps: false
});

export default BookGenre;

