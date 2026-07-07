import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';
import Role from './Role.js';

const User = sequelize.define('User', {
  user_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  role_id: { 
    type: DataTypes.INTEGER, 
    allowNull: false, 
    defaultValue: 2,
    references: { model: Role, key: 'role_id' },
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE'
  },
  login: { type: DataTypes.STRING(100), allowNull: false, unique: true },
  email: { type: DataTypes.STRING(150), allowNull: false, unique: true },
  user_password: { type: DataTypes.STRING(255), allowNull: false },
  birth_date: { type: DataTypes.DATEONLY },
  is_blocked: { type: DataTypes.BOOLEAN, defaultValue: false },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'users',
  timestamps: false
});

export default User;
