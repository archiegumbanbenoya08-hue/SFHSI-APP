import { getConnection } from './db.js';
import { hashPassword } from './middleware/auth.js';
import { recordActivity } from './services/activityLog.js';
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
  let transactionStarted = false;
  try {
    conn = await getConnection();

    // Check if admin exists
    const [admins] = await conn.query('SELECT * FROM admin LIMIT 1');

    if (admins.length > 0) {
      console.log('Admin already exists');
      return;
    }

    await conn.beginTransaction();
    transactionStarted = true;

    const hashedPassword = await hashPassword(adminPassword);

    const [adminResult] = await conn.query(
      'INSERT INTO admin (email, password_hash) VALUES (?, ?)',
      [adminEmail, hashedPassword],
    );
    await recordActivity(conn, {
      actorRole: 'system',
      action: 'admin.created',
      entityType: 'admin',
      entityId: adminResult.insertId,
    });

    console.log('Admin created successfully');
    console.log(`Email: ${adminEmail}`);

    const parentHashedPassword = await hashPassword(parentPassword);

    const [parentResult] = await conn.query(
      'INSERT INTO parent (email, password_hash, name) VALUES (?, ?, ?)',
      [parentEmail, parentHashedPassword, 'Sample Parent']
    );
    await recordActivity(conn, {
      actorRole: 'system',
      action: 'parent.created',
      entityType: 'parent',
      entityId: parentResult.insertId,
      parentId: parentResult.insertId,
    });
    await conn.commit();
    transactionStarted = false;

    console.log('Parent account created');
    console.log(`Email: ${parentEmail}`);

  } catch (err) {
    if (conn && transactionStarted) {
      try {
        await conn.rollback();
      } catch (rollbackError) {
        console.error('Failed to roll back account seeding:', rollbackError);
      }
    }
    console.error('Seeding error:', err);
    process.exitCode = 1;
  } finally {
    conn?.release();
  }
}

seedDatabase();
