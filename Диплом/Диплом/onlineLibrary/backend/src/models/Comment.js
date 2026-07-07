import { DataTypes } from 'sequelize';
import { sequelize } from '../config/config.js';

const Comment = sequelize.define('Comment', {
  comment_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
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
  comment_text: { type: DataTypes.TEXT, allowNull: false },
  parent_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: { model: 'comments', key: 'comment_id' },
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE'
  },
  is_admin_reply: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  created_at: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW, field: 'writing_date' }
}, {
  tableName: 'comments',
  timestamps: false
});

export default Comment;
