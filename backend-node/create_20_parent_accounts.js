import mysql from 'mysql2/promise';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';

dotenv.config();

const config = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'scmcies_db',
};

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

const conn = await mysql.createConnection({
  host: config.host,
  user: config.user,
  password: config.password,
  database: config.database,
});

for (const account of parentAccounts) {
  const hash = await bcrypt.hash(parentPasswords[account.email], 10);
  await conn.execute(
    'INSERT INTO parent (email, password_hash, name) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash), name = VALUES(name)',
    [account.email, hash, account.name]
  );
  console.log(`Created/updated: ${account.email}`);
}

await conn.end();
console.log('Done: 20 parent accounts created/updated.');
