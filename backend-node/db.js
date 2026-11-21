import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();

const { Pool } = pg;
const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL must be configured for the PostgreSQL backend.');
}

const pool = new Pool({
  connectionString,
  max: 10,
  connectionTimeoutMillis: 5000,
});

export async function getConnection() {
  return pool.connect();
}

export default pool;
