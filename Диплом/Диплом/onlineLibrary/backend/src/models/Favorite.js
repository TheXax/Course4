import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Favorite = sequelize.define('Favorite', {
  favorite_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'users', key: 'user_id' },
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE'
  },
  book_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'books', key: 'book_id' },
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE'
  },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'favorites',
  timestamps: false,
  indexes: [
    {
      unique: true,
      fields: ['user_id', 'book_id']
    }
  ]
});

export default Favorite;

