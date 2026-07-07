import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Author = sequelize.define('Author', {
  author_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  author_name: { type: DataTypes.STRING(150), allowNull: false }
}, {
  tableName: 'authors',
  timestamps: false
});

export default Author;
