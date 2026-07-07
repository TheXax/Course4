import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Quote = sequelize.define('Quote', {
  quote_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'users', key: 'user_id' }, onDelete: 'CASCADE' },
  book_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'books', key: 'book_id' }, onDelete: 'CASCADE' },
  quote_text: { type: DataTypes.TEXT, allowNull: false },
  color: { type: DataTypes.TEXT, defaultValue: 'yellow' },
  page: { type: DataTypes.INTEGER, allowNull: false },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'quotes',
  timestamps: false
});

export default Quote;