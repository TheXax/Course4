import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import User from '../models/User.js';
dotenv.config();

const secret = process.env.JWT_SECRET || 'secret123';

export function signToken(payload) {
  return jwt.sign(payload, secret, { expiresIn: '7d' });
}

export async function optionalAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header) return next();
  const token = header.split(' ')[1];
  if (!token) return next();
  try {
    const decoded = jwt.verify(token, secret);
    req.user = { ...decoded };
    if (!req.user.birth_date && req.user.user_id) {
      try {
        const u = await User.findByPk(req.user.user_id, { attributes: ['birth_date'] });
        if (u?.birth_date) {
          const d = u.birth_date;
          req.user.birth_date = d instanceof Date ? d.toISOString().slice(0, 10) : String(d).slice(0, 10);
        }
      } catch (e) {
        console.error('optionalAuth birth_date:', e);
      }
    }
  } catch {
    // гость
  }
  next();
}

export async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header) return res.status(401).json({ message: 'Нет токена' });
  const token = header.split(' ')[1];
  try {
    const decoded = jwt.verify(token, secret);
    req.user = { ...decoded };
    if (!req.user.birth_date && req.user.user_id) {
      try {
        const u = await User.findByPk(req.user.user_id, { attributes: ['birth_date'] });
        if (u?.birth_date) {
          const d = u.birth_date;
          req.user.birth_date = d instanceof Date ? d.toISOString().slice(0, 10) : String(d).slice(0, 10);
        }
      } catch (e) {
        console.error('authMiddleware birth_date:', e);
      }
    }
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Невалидный токен' });
  }
}

export function adminOnly(req, res, next) {
  if (!req.user) return res.status(401).send();
  if (req.user.role_name !== 'admin' && req.user.role_id !== 1) return res.status(403).json({ message: 'Доступ запрещён' });
  next();
}
