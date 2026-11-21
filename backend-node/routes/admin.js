import express from 'express';
import { getConnection } from '../db.js';
import { authenticateAdminToken, hashPassword } from '../middleware/auth.js';

const router = express.Router();

// Get dashboard statistics
router.get('/statistics', authenticateAdminToken, async (req, res) => {
  try {
    const conn = await getConnection();

    // Total registered students
    const { rows: totalStudents } = await conn.query('SELECT COUNT(*)::int as count FROM student');

    // Students currently on campus
    const { rows: onCampus } = await conn.query(`
      SELECT COUNT(DISTINCT student_id)::int as count FROM entry_exit_log
      WHERE student_id IN (
        SELECT id FROM student
      )
      AND (student_id, timestamp) IN (
        SELECT student_id, MAX(timestamp) FROM entry_exit_log GROUP BY student_id
      )
      AND event_type = 'ENTRY'
    `);

    // Today's entries
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const { rows: todayEntries } = await conn.query(
      "SELECT COUNT(*)::int as count FROM entry_exit_log WHERE event_type = 'ENTRY' AND DATE(timestamp) = DATE($1)",
      [today]
    );

    // Today's exits
    const { rows: todayExits } = await conn.query(
      "SELECT COUNT(*)::int as count FROM entry_exit_log WHERE event_type = 'EXIT' AND DATE(timestamp) = DATE($1)",
      [today]
    );

    conn.release();

    res.json({
      totalStudents: totalStudents[0].count,
      studentsOnCampus: onCampus[0].count,
      entriestoday: todayEntries[0].count,
      exitsToday: todayExits[0].count
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve statistics' });
  }
});

// Get recent logs (last 10)
router.get('/recent-logs', authenticateAdminToken, async (req, res) => {
  try {
    const conn = await getConnection();
    const { rows: logs } = await conn.query(`
      SELECT 
        l.id, l.event_type, l.timestamp, l.location,
        s.student_id, s.first_name, s.last_name, s.grade_level, s.image_path,
        p.name as parent_name, p.email as parent_email
      FROM entry_exit_log l
      JOIN student s ON l.student_id = s.id
      JOIN parent p ON s.parent_id = p.id
      ORDER BY l.timestamp DESC
      LIMIT 10
    `);

    conn.release();
    res.json(logs);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve logs' });
  }
});

export default router;
