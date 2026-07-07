import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Library = sequelize.define('Library', {
  library_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'users', key: 'user_id' }, onDelete: 'CASCADE' },
  book_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'books', key: 'book_id' }, onDelete: 'CASCADE' }
}, {
  tableName: 'library',
  timestamps: false,
  indexes: [
    { unique: true, fields: ['user_id', 'book_id'] }
  ]
});

export default Library;
