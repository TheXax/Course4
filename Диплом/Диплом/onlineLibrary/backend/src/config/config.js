import dotenv from 'dotenv';
import { Sequelize } from 'sequelize';
dotenv.config();

export const sequelize = new Sequelize(
  process.env.DB_NAME || 'online_library',
  process.env.DB_USER || 'pguser',
  process.env.DB_PASS || 'pgpassword',
  {
    host: process.env.DB_HOST || 'db',
    dialect: 'postgres',
    logging: false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    retry: {
      max: 3
    }
  }
);
