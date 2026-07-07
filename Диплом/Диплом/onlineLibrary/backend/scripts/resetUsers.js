import bcrypt from 'bcryptjs';
import { sequelize } from '../src/config/config.js';
import { Op } from 'sequelize';
import Role from '../src/models/Role.js';
import User from '../src/models/User.js';

async function main() {
  await sequelize.authenticate();
  console.log('Connected to DB');

  //существует ли роль админа
  const adminRole = await Role.findOne({ where: { role_name: 'admin' } });
  if (!adminRole) throw new Error('Роль админа не найдена. Сначала запустить initDb.');

  //существует ли пользователь админ
  let admin = await User.findOne({ where: { email: 'admin@gmail.com' } });
  if (!admin) {
    const pwdHash = await bcrypt.hash('admin', 10);
    admin = await User.create({ login: 'admin', email: 'admin@gmail.com', user_password: pwdHash, role_id: adminRole.role_id });
    console.log('Created admin user admin@gmail.com');
  } else {
    //пользователь админ имеет права админа
    if (admin.role_id !== adminRole.role_id) {
      admin.role_id = adminRole.role_id;
      await admin.save();
    }
  }

  //удаление других пользователей

  const deleted = await User.destroy({ where: { email: { [Op.ne]: 'admin@gmail.com' } } });
  console.log(`Deleted ${deleted} users`);
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
