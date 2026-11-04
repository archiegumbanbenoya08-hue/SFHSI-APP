import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';

export function generateAdminToken(adminId, email) {
  return jwt.sign(
    { id: adminId, email, role: 'admin' },
    process.env.JWT_ADMIN_SECRET,
    { expiresIn: '7d' }
  );
}

export function generateParentToken(parentId, email) {
  return jwt.sign(
    { id: parentId, email, role: 'parent' },
    process.env.JWT_PARENT_SECRET,
    { expiresIn: '7d' }
  );
}

export function verifyAdminToken(token) {
  try {
    return jwt.verify(token, process.env.JWT_ADMIN_SECRET);
  } catch (err) {
    return null;
  }
}

export function verifyParentToken(token) {
  try {
    return jwt.verify(token, process.env.JWT_PARENT_SECRET);
  } catch (err) {
    return null;
  }
}

export async function hashPassword(password) {
  return await bcrypt.hash(password, 10);
}

export async function comparePassword(password, hash) {
  return await bcrypt.compare(password, hash);
}

export function authenticateAdminToken(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const decoded = verifyAdminToken(token);
  if (!decoded) {
    return res.status(401).json({ error: 'Invalid token' });
  }

  req.user = decoded;
  next();
}

export function authenticateParentToken(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const decoded = verifyParentToken(token);
  if (!decoded) {
    return res.status(401).json({ error: 'Invalid token' });
  }

  req.user = decoded;
  next();
}

export function authenticateDevice(req, res, next) {
  const deviceKey = req.headers['x-device-key'];
  if (!deviceKey || deviceKey !== process.env.DEVICE_API_KEY) {
    return res.status(401).json({ error: 'Invalid device key' });
  }
  next();
}
