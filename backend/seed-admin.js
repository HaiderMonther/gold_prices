const { DataSource } = require('typeorm');
const bcrypt = require('bcrypt');

const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'haider',
  database: process.env.DB_DATABASE || 'gold_system',
  ssl: false,
});

async function seed() {
  try {
    await AppDataSource.initialize();
    console.log('✅ Connected to database');

    const password_hash = await bcrypt.hash('admin123', 10);

    await AppDataSource.query(`
      INSERT INTO users (id, name, username, password_hash, role, is_active, created_at)
      VALUES (
        gen_random_uuid(),
        'Super Admin',
        'superadmin',
        '${password_hash.replace(/'/g, "''")}',
        'super_admin',
        true,
        NOW()
      )
      ON CONFLICT (username) DO NOTHING;
    `);

    console.log('✅ Super admin created successfully!');
    console.log('📋 Username: superadmin');
    console.log('🔑 Password: admin123');
    console.log('⚠️  Please change the password after first login!');

    await AppDataSource.destroy();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

seed();
