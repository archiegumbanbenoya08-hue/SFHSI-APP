import express from 'express';
import { getConnection } from '../db.js';
import { hashPassword, comparePassword, generateAdminToken, generateParentToken } from '../middleware/auth.js';

const router = express.Router();

// Admin Login
router.post('/admin/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const conn = await getConnection();
    const [adminRows] = await conn.query('SELECT id, email, password_hash FROM admin WHERE email = ?', [email]);
    conn.release();

    if (adminRows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const admin = adminRows[0];
    const passwordMatch = await comparePassword(password, admin.password_hash);

    if (!passwordMatch) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = generateAdminToken(admin.id, admin.email);
    res.json({ token, role: 'admin', email: admin.email });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Parent Login
router.post('/parent/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const conn = await getConnection();
    const [parentRows] = await conn.query('SELECT id, email, password_hash, name FROM parent WHERE email = ?', [email]);
    conn.release();

    if (parentRows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const parent = parentRows[0];
    const passwordMatch = await comparePassword(password, parent.password_hash);

    if (!passwordMatch) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = generateParentToken(parent.id, parent.email);
    res.json({ token, role: 'parent', parentId: parent.id, name: parent.name, email: parent.email });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Login failed' });
  }
});

export default router;
