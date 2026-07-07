import bcrypt from 'bcryptjs';
import User from '../models/User.js';
import Role from '../models/Role.js';
import { signToken } from '../utils/auth.js';

export async function register(req, res) {
  try {
    const { login, email, password, admin_key, birth_date } = req.body;

    if (!email || !password || !login || !birth_date)
      return res.status(400).json({ message: 'Отсутствуют обязательные поля' });

    const bd = new Date(birth_date);
    if (Number.isNaN(bd.getTime())) {
      return res.status(400).json({ message: 'Некорректная дата рождения' });
    }

    // Проверяем существование логина
    const existsLogin = await User.findOne({ where: { login } });
    if (existsLogin)
      return res.status(409).json({ message: 'Логин занят' });

    // Проверяем существование email
    const existsEmail = await User.findOne({ where: { email } });
    if (existsEmail)
      return res.status(409).json({ message: 'Пользователь с данной почтой уже зарегистрирован' });

    const hash = await bcrypt.hash(password, 10);

    let role_id = 2; // дефолтное

    if (admin_key && admin_key === process.env.ADMIN_KEY) {
      role_id = 1; // админ
    }

    const user = await User.create({
      login,
      email,
      user_password: hash,
      birth_date: bd,
      role_id
    });

    return res.json({
      user_id: user.user_id,
      email: user.email,
      role: role_id === 1 ? 'admin' : 'user'
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Ошибка сервера' });
  }
}


export async function login(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ message: 'Отсутствуют обязательные поля' });
    const user = await User.findOne({ where: { email }, include: Role });
    if (!user) return res.status(404).json({ message: 'Пользователь с данной почтой не зарегистрирован' });
    if (user.is_blocked) return res.status(403).json({ message: 'Пользователь заблокирован' });
    const ok = await bcrypt.compare(password, user.user_password);
    if (!ok) return res.status(401).json({ message: 'Неправильный пароль' });
    const birthDateStr = user.birth_date
      ? (user.birth_date instanceof Date ? user.birth_date.toISOString().slice(0, 10) : String(user.birth_date).slice(0, 10))
      : null;
    const token = signToken({
      user_id: user.user_id,
      role_id: user.role_id,
      role_name: user.Role?.role_name || 'user',
      login: user.login,
      birth_date: birthDateStr
    });
    res.json({
      token,
      user: {
        user_id: user.user_id,
        login: user.login,
        role: user.Role?.role_name || 'user',
        birth_date: birthDateStr
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Произошла ошибка на сервере' });
  }
}
