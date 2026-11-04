import { getConnection } from './db.js';
import { hashPassword } from './middleware/auth.js';
import dotenv from 'dotenv';

dotenv.config();

async function seedDatabase() {
  const adminEmail = process.env.ADMIN_EMAIL;
  const adminPassword = process.env.ADMIN_PASSWORD;
  const parentEmail = process.env.PARENT_EMAIL;
  const parentPassword = process.env.PARENT_PASSWORD;
  if (![adminEmail, adminPassword, parentEmail, parentPassword].every((value) => value?.trim())) {
    console.error('Seeding error: Set ADMIN_EMAIL, ADMIN_PASSWORD, PARENT_EMAIL, and PARENT_PASSWORD in your local .env file.');
    process.exitCode = 1;
    return;
  }

  let conn;
  try {
    conn = await getConnection();

    // Check if admin exists
    const [admins] = await conn.query('SELECT * FROM admin LIMIT 1');

    if (admins.length > 0) {
      console.log('Admin already exists');
      conn.release();
      return;
    }

    // Create first admin
    const hashedPassword = await hashPassword(adminPassword);

    await conn.query('INSERT INTO admin (email, password_hash) VALUES (?, ?)', [adminEmail, hashedPassword]);

    console.log('Admin created successfully');
    console.log(`Email: ${adminEmail}`);

    const parentHashedPassword = await hashPassword(parentPassword);

    const [parentResult] = await conn.query(
      'INSERT INTO parent (email, password_hash, name) VALUES (?, ?, ?)',
      [parentEmail, parentHashedPassword, 'Sample Parent']
    );

    console.log('Parent account created');
    console.log(`Email: ${parentEmail}`);

  } catch (err) {
    console.error('Seeding error:', err);
    process.exitCode = 1;
  } finally {
    conn?.release();
  }
}

seedDatabase();
