import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Publisher = sequelize.define('Publisher', {
  publisher_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  publisher_name: { type: DataTypes.STRING(150), allowNull: false }
}, {
  tableName: 'publishers',
  timestamps: false
});

export default Publisher;
