import User from '../models/User.js';
import Role from '../models/Role.js';

export async function listUsers(req, res) {
  const users = await User.findAll({ include: Role });
  res.json(users);
}

export async function blockUser(req, res) {
  const { id } = req.params;
  //админ не может себя блокнуть
  if (parseInt(id) === req.user.user_id) return res.status(400).json({ message: "Невозможно заблокировать себя" });
  const user = await User.findByPk(id);
  if (!user) return res.status(404).json({ message: 'Не найдено' });
  user.is_blocked = true;
  await user.save();
  res.json({ message: 'Заблокирован' });
}

export async function unblockUser(req, res) {
  const { id } = req.params;
  //админ не может себя разблокировать
  if (parseInt(id) === req.user.user_id) return res.status(400).json({ message: "Невозможно разблокировать себя" });
  const user = await User.findByPk(id);
  if (!user) return res.status(404).json({ message: 'Не найдено' });
  user.is_blocked = false;
  await user.save();
  res.json({ message: 'Разблокирован' });
}
