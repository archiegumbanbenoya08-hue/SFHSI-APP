import express from 'express';
import { getConnection } from '../db.js';
import { authenticateAdminToken, authenticateParentToken, authenticateDevice } from '../middleware/auth.js';
import { sendEntryNotification, sendExitNotification, sendAdminEntryNotification, sendAdminExitNotification } from '../services/email.js';

const router = express.Router();

// Post log from Mini PC (Device key protected)
router.post('/', authenticateDevice, async (req, res) => {
  try {
    const { student_id, event_type, confidence_score, location } = req.body;

    if (!student_id || !event_type || !['ENTRY', 'EXIT'].includes(event_type)) {
      return res.status(400).json({ error: 'Invalid log data' });
    }

    const conn = await getConnection();

    // Get student info including parent details
    const [students] = await conn.query(
      'SELECT s.id, s.first_name, s.last_name, s.grade_level, s.parent_email, p.name as parent_name FROM student s JOIN parent p ON s.parent_id = p.id WHERE s.student_id = ?',
      [student_id]
    );

    if (students.length === 0) {
      conn.release();
      return res.status(404).json({ error: 'Student not found' });
    }

    const student = students[0];

    // Insert log
    const [result] = await conn.query(
      'INSERT INTO entry_exit_log (student_id, event_type, confidence_score, location) VALUES (?, ?, ?, ?)',
      [student.id, event_type, confidence_score || null, location || 'Main Gate']
    );

    // Update student status
    const newStatus = event_type === 'ENTRY' ? 'IN_CAMPUS' : 'NOT_IN_CAMPUS';
    await conn.query('UPDATE student SET status = ? WHERE id = ?', [newStatus, student.id]);

    const timestamp = new Date();
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@scmcies.com';

    conn.release();

    // Send emails in parallel using Promise.all
    try {
      if (event_type === 'ENTRY') {
        await Promise.all([
          sendEntryNotification(student.parent_email, student.parent_name, student.first_name + ' ' + student.last_name, student_id, student.grade_level, timestamp),
          sendAdminEntryNotification(adminEmail, student.first_name + ' ' + student.last_name, student_id, student.grade_level, student.parent_email, timestamp)
        ]);
      } else {
        await Promise.all([
          sendExitNotification(student.parent_email, student.parent_name, student.first_name + ' ' + student.last_name, student_id, student.grade_level, timestamp),
          sendAdminExitNotification(adminEmail, student.first_name + ' ' + student.last_name, student_id, student.grade_level, student.parent_email, timestamp)
        ]);
      }
    } catch (emailErr) {
      console.error('Email sending error:', emailErr);
      // Continue even if email fails
    }

    res.status(201).json({
      id: result.insertId,
      student_id,
      event_type,
      timestamp,
      confidence_score,
      location,
      message: 'Log created successfully'
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create log' });
  }
});

// Get last log for a student (Device key protected - for cooldown logic)
router.get('/last/:studentId', authenticateDevice, async (req, res) => {
  try {
    const studentId = req.params.studentId;

    const conn = await getConnection();
    const [logs] = await conn.query(
      'SELECT * FROM entry_exit_log WHERE student_id = (SELECT id FROM student WHERE student_id = ?) ORDER BY timestamp DESC LIMIT 1',
      [studentId]
    );
    conn.release();

    if (logs.length === 0) {
      // Student not in logs, first time entry
      return res.json({ event_type: 'EXIT' }); // Return EXIT so next event will be ENTRY
    }

    res.json(logs[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve log' });
  }
});

// Get all logs with filters (Admin only)
router.get('/admin/all', authenticateAdminToken, async (req, res) => {
  try {
    const { student_id, event_type, startDate, endDate } = req.query;

    let query = `
      SELECT 
        l.id, l.event_type, l.timestamp, l.location, l.confidence_score,
        s.student_id, s.first_name, s.last_name, s.grade_level, s.image_path,
        p.name as parent_name, p.email as parent_email
      FROM entry_exit_log l
      JOIN student s ON l.student_id = s.id
      JOIN parent p ON s.parent_id = p.id
      WHERE 1=1
    `;

    const params = [];

    if (student_id) {
      query += ' AND s.student_id = ?';
      params.push(student_id);
    }

    if (event_type && ['ENTRY', 'EXIT'].includes(event_type)) {
      query += ' AND l.event_type = ?';
      params.push(event_type);
    }

    if (startDate) {
      query += ' AND l.timestamp >= ?';
      params.push(new Date(startDate));
    }

    if (endDate) {
      query += ' AND l.timestamp <= ?';
      params.push(new Date(endDate));
    }

    query += ' ORDER BY l.timestamp DESC LIMIT 1000';

    const conn = await getConnection();
    const [logs] = await conn.query(query, params);
    conn.release();

    res.json(logs);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve logs' });
  }
});

// Get logs for parent's children (Parent only)
router.get('/parent/:parentId', authenticateParentToken, async (req, res) => {
  try {
    const parentId = req.params.parentId;

    // Verify parent can only access their own logs
    if (String(req.user.id) !== String(parentId)) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const conn = await getConnection();
    const [logs] = await conn.query(
      `SELECT 
        l.id, l.event_type, l.timestamp, l.location,
        s.student_id, s.first_name, s.last_name, s.grade_level, s.image_path
      FROM entry_exit_log l
      JOIN student s ON l.student_id = s.id
      WHERE s.parent_id = ?
      ORDER BY l.timestamp DESC
      LIMIT 500`,
      [parentId]
    );

    conn.release();

    res.json(logs);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve logs' });
  }
});

export default router;
