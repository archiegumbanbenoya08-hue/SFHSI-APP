import express from 'express';
import { getConnection } from '../db.js';
import { authenticateAdminToken, authenticateParentToken } from '../middleware/auth.js';

const router = express.Router();
const MAX_ACTIVITY_LOGS = 500;

function getLimit(value) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) return 100;
  return Math.max(1, Math.min(parsed, MAX_ACTIVITY_LOGS));
}

router.get('/admin', authenticateAdminToken, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const [logs] = await conn.query(
      `SELECT id, actor_role, actor_id, actor_email, action, entity_type, entity_id,
              parent_id, details, created_at
       FROM activity_log
       ORDER BY created_at DESC, id DESC
       LIMIT ?`,
      [getLimit(req.query.limit)],
    );
    res.json(logs);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve activity logs' });
  } finally {
    conn?.release();
  }
});

router.get('/parent', authenticateParentToken, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const [logs] = await conn.query(
      `SELECT id, actor_role, actor_id, actor_email, action, entity_type, entity_id,
              parent_id, details, created_at
       FROM activity_log
       WHERE parent_id = ?
          OR (actor_role = 'parent' AND actor_id = ?)
       ORDER BY created_at DESC, id DESC
       LIMIT ?`,
      [req.user.id, req.user.id, getLimit(req.query.limit)],
    );
    res.json(logs);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve activity logs' });
  } finally {
    conn?.release();
  }
});

export default router;
