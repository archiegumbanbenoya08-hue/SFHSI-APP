import express from 'express';
import { getConnection } from '../db.js';
import { authenticateAdminToken, authenticateDevice } from '../middleware/auth.js';
import multer from 'multer';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import sharp from 'sharp';
import { v4 as uuidv4 } from 'uuid';
import fs from 'fs';
import { generateFaceEncoding } from '../services/faceEncoding.js';
import { recordActivity } from '../services/activityLog.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const router = express.Router();

const uploadDir = join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files allowed'));
    }
  }
});

// Get all students with current status (Admin only)
router.get('/', authenticateAdminToken, async (req, res) => {
  try {
    const conn = await getConnection();
    
    const query = `
      SELECT 
        s.id,
        s.student_id,
        s.first_name,
        s.last_name,
        s.grade_level,
        s.section,
        s.parent_id,
        p.email as parent_email,
        p.name as parent_name,
        s.image_path,
        (SELECT event_type FROM entry_exit_log WHERE student_id = s.id ORDER BY timestamp DESC LIMIT 1) as last_status,
        (SELECT timestamp FROM entry_exit_log WHERE student_id = s.id ORDER BY timestamp DESC LIMIT 1) as last_seen
      FROM student s
      JOIN parent p ON s.parent_id = p.id
      ORDER BY s.first_name ASC
    `;

    const [students] = await conn.query(query);
    conn.release();

    const studentsWithStatus = students.map(s => ({
      ...s,
      status: s.last_status === 'ENTRY' ? 'IN_CAMPUS' : 'NOT_IN_CAMPUS'
    }));

    res.json(studentsWithStatus);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve students' });
  }
});

// Register new student with photo (Admin only)
router.post('/', authenticateAdminToken, upload.single('photo'), async (req, res) => {
  let conn;
  let transactionStarted = false;
  let filepath;
  try {
    const { student_id, first_name, last_name, grade_level, section, parent_id } = req.body;

    if (!student_id || !first_name || !last_name || !grade_level || !section || !parent_id || !req.file) {
      return res.status(400).json({ error: 'All fields including photo are required' });
    }

    conn = await getConnection();
    await conn.beginTransaction();
    transactionStarted = true;

    // Verify parent exists and get email
    const [parentRows] = await conn.query('SELECT id, email FROM parent WHERE id = ?', [parent_id]);
    if (parentRows.length === 0) {
      await conn.rollback();
      transactionStarted = false;
      return res.status(400).json({ error: 'Invalid parent ID' });
    }

    const parentEmail = parentRows[0].email;

    // Save photo
    const filename = `${uuidv4()}.jpg`;
    filepath = join(uploadDir, filename);
    await sharp(req.file.buffer).resize(300, 300).toFile(filepath);
    const imagePath = `/uploads/${filename}`;

    let faceEncoding = null;
    try {
      // Generate face encoding automatically
      const encoding = await generateFaceEncoding(filepath);
      if (encoding) {
        faceEncoding = JSON.stringify(encoding);
      }
    } catch (err) {
      console.warn('Face encoding generation failed:', err.message);
      // Continue without encoding - can be added later
    }

    // Insert student
    const [result] = await conn.query(
      'INSERT INTO student (student_id, first_name, last_name, grade_level, section, parent_id, parent_email, image_path, face_encoding) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [student_id, first_name, last_name, grade_level, section, parent_id, parentEmail, imagePath, faceEncoding]
    );

    await recordActivity(conn, {
      actorRole: 'admin',
      actorId: req.user.id,
      actorEmail: req.user.email,
      action: 'student.created',
      entityType: 'student',
      entityId: result.insertId,
      parentId: parentRows[0].id,
      details: { student_id },
    });
    await conn.commit();
    transactionStarted = false;

    res.status(201).json({
      id: result.insertId,
      student_id,
      first_name,
      last_name,
      grade_level,
      section,
      parent_id,
      parent_email: parentEmail,
      image_path: imagePath,
      face_encoding_status: faceEncoding ? 'generated' : 'pending',
      message: 'Student registered successfully'
    });
  } catch (err) {
    if (conn && transactionStarted) {
      try {
        await conn.rollback();
      } catch (rollbackError) {
        console.error('Failed to roll back student creation:', rollbackError);
      }
    }
    if (filepath && fs.existsSync(filepath)) {
      try {
        fs.unlinkSync(filepath);
      } catch (cleanupError) {
        console.error('Failed to remove student image after rollback:', cleanupError);
      }
    }
    console.error(err);
    res.status(500).json({ error: 'Failed to register student' });
  } finally {
    conn?.release();
  }
});

// Update student (Admin only)
router.put('/:id', authenticateAdminToken, async (req, res) => {
  let conn;
  let transactionStarted = false;
  try {
    const studentId = req.params.id;
    const { first_name, last_name, grade_level, section } = req.body;

    conn = await getConnection();
    await conn.beginTransaction();
    transactionStarted = true;

    const [students] = await conn.query(
      'SELECT student_id, parent_id FROM student WHERE id = ?',
      [studentId],
    );
    if (students.length === 0) {
      await conn.rollback();
      transactionStarted = false;
      return res.status(404).json({ error: 'Student not found' });
    }

    const updateFields = [];
    const updateValues = [];

    if (first_name !== undefined) {
      updateFields.push('first_name = ?');
      updateValues.push(first_name);
    }
    if (last_name !== undefined) {
      updateFields.push('last_name = ?');
      updateValues.push(last_name);
    }
    if (grade_level !== undefined) {
      updateFields.push('grade_level = ?');
      updateValues.push(grade_level);
    }
    if (section !== undefined) {
      updateFields.push('section = ?');
      updateValues.push(section);
    }

    if (updateFields.length === 0) {
      await conn.rollback();
      transactionStarted = false;
      return res.status(400).json({ error: 'No fields to update' });
    }

    updateValues.push(studentId);
    const query = `UPDATE student SET ${updateFields.join(', ')} WHERE id = ?`;

    await conn.query(query, updateValues);
    await recordActivity(conn, {
      actorRole: 'admin',
      actorId: req.user.id,
      actorEmail: req.user.email,
      action: 'student.updated',
      entityType: 'student',
      entityId: studentId,
      parentId: students[0].parent_id,
      details: {
        student_id: students[0].student_id,
        changed_fields: updateFields.map((field) => field.split(' ')[0]),
      },
    });
    await conn.commit();
    transactionStarted = false;

    res.json({ message: 'Student updated successfully' });
  } catch (err) {
    if (conn && transactionStarted) {
      try {
        await conn.rollback();
      } catch (rollbackError) {
        console.error('Failed to roll back student update:', rollbackError);
      }
    }
    console.error(err);
    res.status(500).json({ error: 'Failed to update student' });
  } finally {
    conn?.release();
  }
});

// Delete student (Admin only)
router.delete('/:id', authenticateAdminToken, async (req, res) => {
  let conn;
  let transactionStarted = false;
  let imagePath;
  try {
    const studentId = req.params.id;

    conn = await getConnection();
    await conn.beginTransaction();
    transactionStarted = true;
    const [students] = await conn.query(
      'SELECT student_id, parent_id, image_path FROM student WHERE id = ?',
      [studentId],
    );
    if (students.length === 0) {
      await conn.rollback();
      transactionStarted = false;
      return res.status(404).json({ error: 'Student not found' });
    }

    imagePath = students[0].image_path;
    await conn.query('DELETE FROM student WHERE id = ?', [studentId]);
    await recordActivity(conn, {
      actorRole: 'admin',
      actorId: req.user.id,
      actorEmail: req.user.email,
      action: 'student.deleted',
      entityType: 'student',
      entityId: studentId,
      parentId: students[0].parent_id,
      details: { student_id: students[0].student_id },
    });
    await conn.commit();
    transactionStarted = false;

    if (imagePath) {
      const filepath = join(__dirname, '..', imagePath);
      if (fs.existsSync(filepath)) {
        try {
          fs.unlinkSync(filepath);
        } catch (cleanupError) {
          console.error('Failed to remove student image after database deletion:', cleanupError);
        }
      }
    }

    res.json({ message: 'Student deleted successfully' });
  } catch (err) {
    if (conn && transactionStarted) {
      try {
        await conn.rollback();
      } catch (rollbackError) {
        console.error('Failed to roll back student deletion:', rollbackError);
      }
    }
    console.error(err);
    res.status(500).json({ error: 'Failed to delete student' });
  } finally {
    conn?.release();
  }
});

// Get all face encodings (Device key protected - for Mini PC)
router.get('/encodings/all', authenticateDevice, async (req, res) => {
  try {
    const conn = await getConnection();
    const [students] = await conn.query(
      'SELECT id, student_id, first_name, last_name, grade_level, section, parent_id, parent_email, face_encoding FROM student WHERE face_encoding IS NOT NULL'
    );
    conn.release();

    res.json(students);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to retrieve encodings' });
  }
});

// Upload face encoding for a student (Admin only)
router.post('/encoding', authenticateAdminToken, async (req, res) => {
  try {
    const { student_id, face_encoding } = req.body;

    if (!student_id || !face_encoding) {
      return res.status(400).json({ error: 'Student ID and face encoding required' });
    }

    const conn = await getConnection();
    
    // Parse and validate encoding is valid JSON array
    try {
      JSON.parse(face_encoding);
    } catch {
      conn.release();
      return res.status(400).json({ error: 'Invalid face encoding format' });
    }

    const [result] = await conn.query(
      'UPDATE student SET face_encoding = ? WHERE student_id = ?',
      [face_encoding, student_id]
    );

    conn.release();

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Student not found' });
    }

    res.json({ message: 'Face encoding uploaded successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to upload encoding' });
  }
});

export default router;
