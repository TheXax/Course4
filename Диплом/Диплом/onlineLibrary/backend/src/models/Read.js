import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Read = sequelize.define('Read', {
  read_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'users', key: 'user_id' }, onDelete: 'CASCADE' },
  book_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'books', key: 'book_id' }, onDelete: 'CASCADE' }
}, {
  tableName: 'read',
  timestamps: false,
  indexes: [
    { unique: true, fields: ['user_id', 'book_id'] }
  ]
});

export default Read;
