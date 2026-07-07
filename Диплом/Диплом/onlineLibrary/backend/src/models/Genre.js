import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Genre = sequelize.define('Genre', {
  genre_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  genre_name: { type: DataTypes.STRING(100), allowNull: false }
}, {
  tableName: 'genres',
  timestamps: false
});

export default Genre;
