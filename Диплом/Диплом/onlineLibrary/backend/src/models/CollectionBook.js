import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const CollectionBook = sequelize.define('CollectionBook', {
  collection_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    references: { model: 'collections', key: 'collection_id' },
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE'
  },
  book_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    references: { model: 'books', key: 'book_id' },
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE'
  }
}, {
  tableName: 'collection_books',
  timestamps: false
});

export default CollectionBook;
