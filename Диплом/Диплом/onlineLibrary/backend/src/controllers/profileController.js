import bcrypt from 'bcryptjs';
import User from '../models/User.js';
import Role from '../models/Role.js';
import Collection from '../models/Collection.js';
import Favorite from '../models/Favorite.js';

export async function getProfile(req, res) {
  try {
    const user = await User.findByPk(req.user.user_id, {
      include: { model: Role, attributes: ['role_name'] },
      attributes: { exclude: ['user_password'] }
    });
    if (!user) return res.status(404).json({ message: 'Пользователь не найдено' });

    const [collectionsCount, favoritesCount] = await Promise.all([
      Collection.count({ where: { user_id: user.user_id } }),
      Favorite.count({ where: { user_id: user.user_id } })
    ]);

    res.json({ ...user.toJSON(), collectionsCount, favoritesCount });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function updateProfile(req, res) {
  try {
    const userId = req.user.user_id;
    const { login, email, password } = req.body;

    const user = await User.findByPk(userId);
    if (!user) return res.status(404).json({ message: 'Пользователь не найден' });

    if (login && login !== user.login) {
      const exists = await User.findOne({ where: { login } });
      if (exists) return res.status(400).json({ message: 'Login уже используется' });
      user.login = login;
    }
    if (email && email !== user.email) {
      const exists = await User.findOne({ where: { email } });
      if (exists) return res.status(400).json({ message: 'Email уже используется' });
      user.email = email;
    }
    if (password) {
      const hash = await bcrypt.hash(password, 10);
      user.user_password = hash;
    }

    await user.save();

    const updated = await User.findByPk(userId, {
      include: { model: Role, attributes: ['role_name'] },
      attributes: { exclude: ['user_password'] }
    });

    const [collectionsCount, favoritesCount] = await Promise.all([
      Collection.count({ where: { user_id: userId } }),
      Favorite.count({ where: { user_id: userId } })
    ]);

    res.json({ ...updated.toJSON(), collectionsCount, favoritesCount });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}

export async function deleteProfile(req, res) {
  try {
    const userId = req.user.user_id;
    const user = await User.findByPk(userId);
    if (!user) return res.status(404).json({ message: 'Пользователь не найден' });
    await user.destroy();
    res.json({ message: 'Удалено' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
}



