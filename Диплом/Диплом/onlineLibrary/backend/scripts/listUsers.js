import { sequelize } from '../src/config/config.js';
import User from '../src/models/User.js';
import Role from '../src/models/Role.js';
import '../src/models/associations.js';

async function main() {
  await sequelize.authenticate();
  console.log('Connected to DB');

  const users = await User.findAll();
  console.log('Users in DB:');
  for (const u of users) {
    const r = u.role_id ? await Role.findByPk(u.role_id) : null;
    console.log(`${u.user_id}\t${u.email}\t${u.login}\trole=${r?.role_name || u.role_id}\tblocked=${u.is_blocked}\tcreated=${u.created_at}`);
  }
  process.exit(0);
}

main().catch((err) => { console.error(err); process.exit(1); });
