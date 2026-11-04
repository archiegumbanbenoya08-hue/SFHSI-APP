import express from 'express';
import { getConnection } from '../db.js';
import { authenticateParentToken } from '../middleware/auth.js';

const router = express.Router();

// Get parent's children with current status
router.get('/:parentId/children', authenticateParentToken, async (req, res) => {
  try {
    const parentId = req.params.parentId;

    // Verify parent can only access their own children
    if (String(req.user.id) !== String(parentId)) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const conn = await getConnection();
    const query = `
      SELECT 
        s.id,
        s.student_id,
        s.first_name,
        s.last_name,
        s.grade_level,
        s.section,
        s.image_path,
        (SELECT event_type FROM entry_exit_log WHERE student_id = s.id ORDER BY timestamp DESC LIMIT 1) as last_status,
        (SELECT timestamp FROM entry_exit_log WHERE student_id = s.id ORDER BY timestamp DESC LIMIT 1) as last_seen
      FROM student s
      WHERE s.parent_id = ?
      ORDER BY s.first_name ASC
    `;

    const [children] = await conn.query(query, [parentId]);
    conn.release();

    const childrenWithStatus = children.map(c => ({
      ...c,
      status: c.last_status === 'ENTRY' ? 'IN_CAMPUS' : 'NOT_IN_CAMPUS'
    }));

    res.json(childrenWithStatus);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve children' });
  }
});

export default router;
