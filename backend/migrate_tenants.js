const { Client } = require('pg');

async function migrate() {
  const client = new Client({
    host: 'localhost',
    port: 5432,
    user: 'postgres',
    password: 'haider',
    database: 'gold_system',
  });

  await client.connect();
  console.log('Connected to DB');

  // Check existing columns
  const res = await client.query(`
    SELECT column_name FROM information_schema.columns WHERE table_name = 'tenants'
  `);
  const cols = res.rows.map(r => r.column_name);
  console.log('Existing columns:', cols.join(', '));

  // Add tenant_code if missing
  if (!cols.includes('tenant_code')) {
    console.log('Adding tenant_code column...');
    await client.query(`ALTER TABLE tenants ADD COLUMN tenant_code VARCHAR UNIQUE`);
    // Populate it from subdomain for existing records
    await client.query(`UPDATE tenants SET tenant_code = COALESCE(subdomain, 'tenant' || EXTRACT(EPOCH FROM NOW())::TEXT) WHERE tenant_code IS NULL`);
    // Make it NOT NULL
    await client.query(`ALTER TABLE tenants ALTER COLUMN tenant_code SET NOT NULL`);
    console.log('tenant_code added and populated');
  } else {
    console.log('tenant_code already exists');
  }

  // Add logo_url if missing
  if (!cols.includes('logo_url')) {
    console.log('Adding logo_url column...');
    await client.query(`ALTER TABLE tenants ADD COLUMN logo_url VARCHAR`);
    console.log('logo_url added');
  }

  // Add primary_color if missing
  if (!cols.includes('primary_color')) {
    console.log('Adding primary_color column...');
    await client.query(`ALTER TABLE tenants ADD COLUMN primary_color VARCHAR`);
    console.log('primary_color added');
  }

  // Make subdomain nullable if it isn't
  try {
    await client.query(`ALTER TABLE tenants ALTER COLUMN subdomain DROP NOT NULL`);
    console.log('subdomain is now nullable');
  } catch (e) {
    console.log('subdomain already nullable or does not exist');
  }

  // Show final state
  const final = await client.query(`SELECT id, name, tenant_code, subdomain FROM tenants`);
  console.log('Tenants:', JSON.stringify(final.rows, null, 2));

  await client.end();
  console.log('Migration complete!');
}

migrate().catch(e => {
  console.error('Migration error:', e.message);
  process.exit(1);
});
