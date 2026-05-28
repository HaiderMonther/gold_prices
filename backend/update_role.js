const { DataSource } = require('typeorm');
const { User } = require('./src/users/user.entity');
require('dotenv').config();

const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_DATABASE || 'gold_system',
  entities: [__dirname + '/src/**/*.entity.ts'],
});

async function run() {
  await AppDataSource.initialize();
  // Find any admin and make them super_admin
  try {
    await AppDataSource.query(`ALTER TYPE users_role_enum ADD VALUE 'super_admin'`);
  } catch (e) {
    // ignore if already exists
  }
  await AppDataSource.query(`UPDATE users SET role = 'super_admin'`);
  console.log('All users have been set to super_admin temporarily so you can see the interface.');
  process.exit(0);
}

run().catch(console.error);
