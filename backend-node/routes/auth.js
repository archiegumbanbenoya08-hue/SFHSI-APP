import express from 'express';
import { getConnection } from '../db.js';
import { hashPassword, comparePassword, generateAdminToken, generateParentToken } from '../middleware/auth.js';
import { recordActivity } from '../services/activityLog.js';

const router = express.Router();

// Admin Login
router.post('/admin/login', async (req, res) => {
  let conn;
  try {
    const { email, password } = req.body;

    if (typeof email !== 'string' || typeof password !== 'string' || !email.trim() || !password || email.length > 255) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    conn = await getConnection();
    const { rows: adminRows } = await conn.query('SELECT id, email, password_hash FROM admin WHERE email = $1', [email]);

    if (adminRows.length === 0) {
      await recordActivity(conn, {
        actorRole: 'admin',
        actorEmail: email,
        action: 'auth.login.failed',
        entityType: 'admin',
      });
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const admin = adminRows[0];
    const passwordMatch = await comparePassword(password, admin.password_hash);

    if (!passwordMatch) {
      await recordActivity(conn, {
        actorRole: 'admin',
        actorId: admin.id,
        actorEmail: admin.email,
        action: 'auth.login.failed',
        entityType: 'admin',
        entityId: admin.id,
      });
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = generateAdminToken(admin.id, admin.email);
    await recordActivity(conn, {
      actorRole: 'admin',
      actorId: admin.id,
      actorEmail: admin.email,
      action: 'auth.login.succeeded',
      entityType: 'admin',
      entityId: admin.id,
    });
    res.json({ token, role: 'admin', email: admin.email });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Login failed' });
  } finally {
    conn?.release();
  }
});

// Parent Login
router.post('/parent/login', async (req, res) => {
  let conn;
  try {
    const { email, password } = req.body;

    if (typeof email !== 'string' || typeof password !== 'string' || !email.trim() || !password || email.length > 255) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    conn = await getConnection();
    const { rows: parentRows } = await conn.query('SELECT id, email, password_hash, name FROM parent WHERE email = $1', [email]);

    if (parentRows.length === 0) {
      await recordActivity(conn, {
        actorRole: 'parent',
        actorEmail: email,
        action: 'auth.login.failed',
        entityType: 'parent',
      });
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const parent = parentRows[0];
    const passwordMatch = await comparePassword(password, parent.password_hash);

    if (!passwordMatch) {
      await recordActivity(conn, {
        actorRole: 'parent',
        actorId: parent.id,
        actorEmail: parent.email,
        action: 'auth.login.failed',
        entityType: 'parent',
        entityId: parent.id,
      });
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = generateParentToken(parent.id, parent.email);
    await recordActivity(conn, {
      actorRole: 'parent',
      actorId: parent.id,
      actorEmail: parent.email,
      action: 'auth.login.succeeded',
      entityType: 'parent',
      entityId: parent.id,
      parentId: parent.id,
    });
    res.json({ token, role: 'parent', parentId: parent.id, name: parent.name, email: parent.email });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Login failed' });
  } finally {
    conn?.release();
  }
});

export default router;
