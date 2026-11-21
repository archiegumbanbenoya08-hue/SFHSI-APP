import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
import { getConnection } from './db.js';
import { recordActivity } from './services/activityLog.js';

dotenv.config();

const parentAccounts = Array.from({ length: 20 }, (_, index) => {
  const number = String(index + 1).padStart(2, '0');
  const numberName = [
    'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
    'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen',
    'Eighteen', 'Nineteen', 'Twenty',
  ][index];
  return {
    name: `Parent ${numberName}`,
    email: `parent${number}@scmcies.com`,
  };
});

let parentPasswords;
try {
  parentPasswords = JSON.parse(process.env.PARENT_ACCOUNT_PASSWORDS || '{}');
} catch (error) {
  throw new Error('PARENT_ACCOUNT_PASSWORDS must be a JSON object mapping account emails to passwords.', { cause: error });
}

for (const account of parentAccounts) {
  if (typeof parentPasswords[account.email] !== 'string' || parentPasswords[account.email].trim().length < 8) {
    throw new Error(`Set a unique password of at least 8 characters for ${account.email} in PARENT_ACCOUNT_PASSWORDS.`);
  }
}

const conn = await getConnection();
try {
  await conn.query('BEGIN');
  for (const account of parentAccounts) {
    const hash = await bcrypt.hash(parentPasswords[account.email], 10);
    const { rows } = await conn.query(
      `INSERT INTO parent (email, password_hash, name) VALUES ($1, $2, $3)
       ON CONFLICT (email) DO UPDATE
       SET password_hash = EXCLUDED.password_hash, name = EXCLUDED.name
       RETURNING id`,
      [account.email, hash, account.name],
    );
    await recordActivity(conn, {
      actorRole: 'system',
      action: 'parent.provisioned',
      entityType: 'parent',
      entityId: rows[0].id,
      parentId: rows[0].id,
    });
    console.log(`Created/updated: ${account.email}`);
  }
  await conn.query('COMMIT');
  console.log('Done: 20 parent accounts created/updated.');
} catch (error) {
  await conn.query('ROLLBACK');
  throw error;
} finally {
  conn.release();
}
