import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Collection = sequelize.define('Collection', {
  collection_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'users', key: 'user_id' },
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE'
  },
  collection_name: { type: DataTypes.STRING(150), allowNull: false }
}, {
  tableName: 'collections',
  timestamps: false
});

export default Collection;
