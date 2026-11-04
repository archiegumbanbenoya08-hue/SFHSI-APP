import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

dotenv.config();

const requiredSecrets = ['JWT_ADMIN_SECRET', 'JWT_PARENT_SECRET', 'DEVICE_API_KEY'];
const missingSecrets = requiredSecrets.filter((name) => !process.env[name]?.trim());
if (missingSecrets.length > 0) {
  throw new Error(`Missing required environment variables: ${missingSecrets.join(', ')}`);
}

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static files for student photos
app.use('/uploads', express.static(join(__dirname, 'uploads')));

// Routes
import authRoutes from './routes/auth.js';
import studentRoutes from './routes/students.js';
import logRoutes from './routes/logs.js';
import parentRoutes from './routes/parents.js';
import adminRoutes from './routes/admin.js';

app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/logs', logRoutes);
app.use('/api/parents', parentRoutes);
app.use('/api/admin', adminRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({ 
    error: err.message || 'Internal server error' 
  });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
