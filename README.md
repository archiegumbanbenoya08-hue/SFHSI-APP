# SCMCIES - Student Campus Entry/Exit Monitoring System

A complete, fully functional student campus monitoring system with face recognition on a Mini PC and web dashboards for administrators and parents.

## System Overview

The SCMCIES system includes:

1. **Mini PC Client** - Face recognition Python script that runs at the campus gate
2. **Node.js Backend** - Attendance REST API with JWT authentication, database management, and email notifications
3. **FastAPI Backend** - Mobile API used by Flutter for account, student, messaging, and activity data
4. **React and Flutter apps** - Web and mobile dashboards for administrators and parents

## Architecture Flow

```
Student enters campus
         ↓
Mini PC detects face using webcam
         ↓
Compares against known encodings (tolerance 0.5)
         ↓
Gets last log from backend (ENTRY or EXIT logic)
         ↓
Posts log to backend API
         ↓
Backend saves log and sends emails to parent + admin
         ↓
Web dashboards update in real-time (30-second refresh)
```

## Prerequisites

### System Requirements
- Windows/Linux/Mac with Python 3.8+ for the Mini PC client
- Python 3.10+ for the FastAPI backend
- Node.js 14+ and npm
- MySQL 5.7+ or MySQL 8.0
- Modern web browser

### Installation Requirements
- dlib with CMake and Visual Studio Build Tools (for face_recognition on Windows)
- Gmail account with App Password configured
- Device API key (any secure random string)

## Quick Start

### 1. Database Setup

#### Windows
```bash
# Open Command Prompt as Administrator
cd c:\Users\Admin\Desktop\SCMCIES APP

# Start MySQL (assuming XAMPP or local MySQL)
mysql -u root < backend-node\schema.sql
```

#### Linux/Mac
```bash
mysql -u root -p < backend-node/schema.sql
# Enter your MySQL password when prompted
```

For an existing database, apply the activity log migration (the full schema contains indexes that are not intended to be recreated).

Windows Command Prompt:

```cmd
mysql -u root -p scmcies_db < backend-node\migrations\001_activity_log.sql
```

Linux/macOS:

```sh
mysql -u root -p scmcies_db < backend-node/migrations/001_activity_log.sql
```

### 2. Backend Setup

```bash
cd backend-node

# Create .env file from example
copy .env.example .env

# OR on Linux/Mac:
cp .env.example .env

# Edit .env with your configuration
```

#### Configure Backend (.env)
```
NODE_ENV=development
PORT=8000

# Database
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=scmcies_db

# JWT Secrets (generate random strings)
JWT_ADMIN_SECRET=<unique random secret, at least 32 characters>
JWT_PARENT_SECRET=<unique random secret, at least 32 characters>
DEVICE_API_KEY=<unique random secret, at least 32 characters>

# Gmail Configuration
GMAIL_USER=your_email@gmail.com
GMAIL_APP_PASSWORD=your_gmail_app_password

# Server URLs
FRONTEND_URL=http://localhost:3000
SERVER_URL=http://localhost:8000

# Admin email
ADMIN_EMAIL=admin@scmcies.com
ADMIN_PASSWORD=<set a unique password>
PARENT_EMAIL=parent@example.com
PARENT_PASSWORD=<set a unique password>
```

#### Install Backend Dependencies
```bash
npm install
```

#### Seed Initial Admin Account
```bash
node seed.js
```

This creates:
- **Admin**: admin@scmcies.com / your_configured_admin_password
- **Parent**: parent@example.com / your_configured_parent_password

#### Start Backend
```bash
npm start
# Or for development with auto-reload:
npm run dev
```

Server should be running at http://localhost:8000

#### Activity Logs

The backend stores non-attendance activity in MySQL's `activity_log` table:

- Successful and failed administrator and parent sign-ins.
- Administrator-created student records, updates, and deletions.
- Administrator and parent account provisioning performed by the setup scripts.

Student changes and their activity records are written in one database transaction. Attendance remains in `entry_exit_log` and is not copied into the activity log. Passwords and authentication tokens are never recorded.

Authenticated API endpoints:

- `GET /api/activity/admin?limit=100` — administrator activity.
- `GET /api/activity/parent?limit=100` — activity for the signed-in parent and their linked student records.

### 3. FastAPI Setup for Flutter

The Flutter app uses FastAPI for login and database-backed account profiles, student records, messages, and activity. FastAPI shares the MySQL database and JWT secrets with the Node.js backend. It does not write attendance events to `activity_log`.

For an existing database, apply the migrations once, in order. The FastAPI migration `002_flutter_data.sql` adds the admin name column and message table; do not run it if you already applied equivalent schema changes.

Windows Command Prompt:

```cmd
mysql -u root -p scmcies_db < backend-node\migrations\001_activity_log.sql
mysql -u root -p scmcies_db < backend-fastapi\migrations\002_flutter_data.sql
```

Linux/macOS:

```sh
mysql -u root -p scmcies_db < backend-node/migrations/001_activity_log.sql
mysql -u root -p scmcies_db < backend-fastapi/migrations/002_flutter_data.sql
```

For a new database created from `backend-node\schema.sql`, these tables and columns are already present, so migrations are not needed.

```powershell
cd backend-fastapi
copy .env.example .env
python -m pip install -r requirements.txt
```

Set `DB_HOST`, `DB_USER`, `DB_PASSWORD`, and `DB_NAME` to the same database used by Node.js. Copy the exact `JWT_ADMIN_SECRET` and `JWT_PARENT_SECRET` values from `backend-node\.env`; the services must use matching secrets. Start the API:

```powershell
python -m uvicorn main:app --host 0.0.0.0 --port 8001
```

Configure the Flutter API URL when running the app:

```powershell
# Android emulator talking to a FastAPI server on the development computer
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001/api

# Windows, macOS, or Flutter web on the same computer
flutter run --dart-define=API_BASE_URL=http://localhost:8001/api
```

For a physical phone, use the development computer's LAN IP instead of `10.0.2.2` and allow the phone through the firewall. Use HTTPS for deployed services. If using Flutter web, add its exact origin to FastAPI's `FRONTEND_URL`.

### 4. Frontend Setup

```bash
cd frontend

# Create .env file
copy .env.example .env

# OR on Linux/Mac:
cp .env.example .env

# Install dependencies
npm install

# Start development server
npm start
```

Frontend should open at http://localhost:3000

### 5. Mini PC Client Setup

#### Install dlib and face_recognition Dependencies

**Windows:**
```bash
# Download and install:
# 1. Visual Studio Build Tools (select C++ workload)
# 2. CMake from https://cmake.org/download/
# 3. Git from https://git-scm.com/

# Install Python packages
cd mini_pc_client
pip install -r requirements.txt
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install build-essential cmake git python3-dev

cd mini_pc_client
pip install -r requirements.txt
```

**Mac:**
```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install cmake

cd mini_pc_client
pip install -r requirements.txt
```

#### Configure Mini PC Client

```bash
cd mini_pc_client

# Create .env file
copy .env.example .env

# OR on Linux/Mac:
cp .env.example .env

# Edit .env
```

#### Configure Mini PC (.env)
```
API_URL=http://localhost:8000
DEVICE_API_KEY=<same unique device key configured in backend .env>
```

Replace with your actual backend URL and device API key.

#### Start Mini PC Client
```bash
python main.py
```

A window will open showing the webcam feed with face detection overlay.

## Setup Workflows

### Register a New Student

1. **Login to Admin Dashboard**
   - URL: http://localhost:3000/login
   - Email: admin@scmcies.com
   - Password: your_configured_admin_password
   - Role: Administrator

2. **Go to Students Page**
   - Click "Students" in the sidebar

3. **Register Student**
   - Click "Register Student" button
   - Fill in student details:
     - Student ID (e.g., STU001)
     - First Name
     - Last Name
     - Grade Level (e.g., 10A)
     - Section (e.g., A)
     - Parent (select from dropdown)
     - Upload student photo
   - Click "Save"

4. **Generate Face Encoding**
   - After student is registered, the photo is uploaded
   - The face encoding will be automatically available to the Mini PC client

### Configure Gmail App Password

Required for email notifications to work.

1. **Enable 2-Factor Authentication on Gmail**
   - Go to https://myaccount.google.com
   - Click "Security" in left menu
   - Enable 2-Factor Authentication

2. **Create App Password**
   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" and "Windows Computer" (or your platform)
   - Google will generate a 16-character password
   - Copy this password

3. **Configure in Backend .env**
   ```
   GMAIL_USER=your_email@gmail.com
   GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
   ```

### Test the System

1. **Start all services**
   - Backend: `npm start` (in backend-node folder)
   - Frontend: `npm start` (in frontend folder)
   - Mini PC Client: `python main.py` (in mini_pc_client folder)

2. **Position a student in front of the webcam**
   - The Mini PC client will detect the face
   - Show green box = detection processing
   - Show name and action on screen

3. **Check logs**
   - Admin Dashboard → Logs page (auto-refreshes every 30 seconds)
   - Parent Dashboard → Logs page (filtered for their children)

4. **Check email notifications**
   - After an entry/exit event, check the parent and admin email accounts
   - Should receive notification with student name, time, and event type

## API Endpoints

### Authentication
- `POST /api/auth/admin/login` - Admin login
- `POST /api/auth/parent/login` - Parent login

### Students (Admin Only)
- `GET /api/students` - Get all students
- `POST /api/students` - Register new student
- `PUT /api/students/:id` - Update student
- `DELETE /api/students/:id` - Delete student
- `GET /api/students/encodings/all` - Get face encodings (Device Key)
- `POST /api/students/encoding` - Upload face encoding

### Logs
- `POST /api/logs` - Post entry/exit log (Device Key)
- `GET /api/logs/last/:studentId` - Get last log (Device Key)
- `GET /api/logs/admin/all` - Get all logs with filters (Admin)
- `GET /api/logs/parent/:parentId` - Get logs for parent's children (Parent)

### Admin
- `GET /api/admin/statistics` - Dashboard statistics
- `GET /api/admin/recent-logs` - Recent logs (last 10)

### Parents
- `GET /api/parents/:parentId/children` - Get parent's children

## Features Implemented

### Mini PC Client
✓ Face recognition using face_recognition library
✓ OpenCV webcam feed
✓ Tolerance threshold: 0.5
✓ ENTRY/EXIT determination based on last log
✓ 10-second cooldown per student
✓ Graceful error handling with retry logic (3 attempts)
✓ Silently skips unrecognized faces
✓ Auto-reload encodings every hour
✓ Shows student name and action on screen
✓ Connection retry with exponential backoff

### Backend API
✓ JWT authentication for Admin and Parent roles
✓ Device API key authentication
✓ bcrypt password hashing
✓ Role-based access control middleware
✓ Input validation on all endpoints
✓ CORS configured for frontend origin only
✓ Multipart form data for photo uploads
✓ Image processing with Sharp (resize to 300x300)
✓ Email notifications with Nodemailer
✓ Promise.all for simultaneous email sending
✓ Student photo storage and serving
✓ Comprehensive error handling
✓ Request timeout handling
✓ Database connection pooling

### Frontend - Admin Dashboard
✓ Protected routes with JWT token
✓ Dashboard overview with 4 summary cards
✓ Recent activity table (last 10 events)
✓ Students page with photo thumbnails
✓ Student registration modal with photo upload
✓ Student edit and delete actions
✓ Logs page with advanced filtering
✓ Filter by student ID, event type, date range
✓ Color-coded logs (green=ENTRY, red=EXIT)
✓ Auto-refresh every 30 seconds
✓ Summary statistics (total entries/exits)
✓ Settings page
✓ Sidebar navigation with admin email
✓ Logout functionality
✓ Loading states and error messages
✓ Responsive design

### Frontend - Parent Dashboard
✓ Protected routes filtered for parent only
✓ My Children page with status cards
✓ Student photo, name, ID, grade display
✓ Current campus status indicator
✓ Last seen timestamp
✓ Logs page for child entry/exit
✓ Filter logs by child (dropdown)
✓ Color-coded events (green=ENTRY, red=EXIT)
✓ Sidebar with parent name and logout
✓ Loading states and error messages

### Email Notifications
✓ Sent on entry: Goes to parent and admin
✓ Sent on exit: Goes to parent and admin
✓ Includes student name, ID, grade, timestamp
✓ Parent email: Personalized with parent name
✓ Admin email: Includes parent contact info
✓ Uses Promise.all for simultaneous sending
✓ Graceful failure (doesn't crash if email fails)

## File Structure

```
SCMCIES APP/
├── backend-node/              # Node.js/Express backend
│   ├── routes/               # API routes
│   │   ├── auth.js
│   │   ├── students.js
│   │   ├── logs.js
│   │   ├── parents.js
│   │   └── admin.js
│   ├── middleware/           # Authentication middleware
│   │   └── auth.js
│   ├── services/             # Business logic
│   │   └── email.js
│   ├── uploads/              # Student photo storage
│   ├── server.js             # Express server
│   ├── db.js                 # Database connection
│   ├── seed.js               # Initial data seeding
│   ├── schema.sql            # Database schema
│   ├── package.json
│   ├── .env.example
│   └── .env                  # (Create from example)
│
├── mini_pc_client/           # Python Mini PC face recognition
│   ├── main.py               # Main face recognition script
│   ├── encoder.py            # Face encoding utility
│   ├── requirements.txt
│   ├── .env.example
│   └── .env                  # (Create from example)
│
├── frontend/                 # React frontend
│   ├── public/
│   │   └── index.html
│   ├── src/
│   │   ├── pages/
│   │   │   ├── LoginPage.jsx
│   │   │   ├── AdminDashboard.jsx
│   │   │   ├── admin/
│   │   │   │   ├── AdminOverview.jsx
│   │   │   │   ├── AdminStudents.jsx
│   │   │   │   ├── AdminLogs.jsx
│   │   │   │   └── AdminSettings.jsx
│   │   │   ├── ParentDashboard.jsx
│   │   │   └── parent/
│   │   │       ├── ParentChildren.jsx
│   │   │       └── ParentLogs.jsx
│   │   ├── components/
│   │   │   └── Sidebar.jsx
│   │   ├── context/
│   │   │   └── AuthContext.jsx
│   │   ├── services/
│   │   │   └── api.js
│   │   ├── App.jsx
│   │   ├── index.jsx
│   │   └── index.css
│   ├── package.json
│   ├── tailwind.config.js
│   ├── postcss.config.js
│   ├── .env.example
│   └── .env                  # (Create from example)
│
├── backend-node/schema.sql
└── README.md
```

## Troubleshooting

### Mini PC Client Issues

**"No module named 'face_recognition'"**
- Install dlib first (requires CMake and build tools)
- On Windows: Install Visual Studio Build Tools with C++ support
- Run: `pip install dlib` then `pip install face-recognition`

**"Cannot connect to API"**
- Verify backend is running on http://localhost:8000
- Check .env file has correct API_URL
- Check DEVICE_API_KEY matches backend

**"No faces detected"**
- Ensure adequate lighting
- Face should be clearly visible in front of webcam
- Try moving closer to camera

**"Press 'q' to quit hangs"**
- This is normal - the client is running continuously
- Use Ctrl+C in terminal to force exit

### Backend Issues

**"Cannot connect to MySQL"**
- Verify MySQL is running
- Check DB_HOST, DB_USER, DB_PASSWORD in .env
- Verify database exists: `mysql -u root` then `SHOW DATABASES;`

**"Port 8000 already in use"**
- Change PORT in .env to another port
- Or kill process: `lsof -ti:8000 | xargs kill -9` (on Mac/Linux)

**"Emails not sending"**
- Verify Gmail account has 2FA enabled
- Verify App Password is correct (not regular password)
- Check GMAIL_USER is correct email address
- Check credentials in .env

**"CORS errors in console"**
- Verify FRONTEND_URL in backend .env matches your frontend URL
- Verify frontend is using correct API_URL

### Frontend Issues

**"Cannot login"**
- Verify backend is running
- Check REACT_APP_API_URL in .env
- Verify credentials in seed or admin creation

**"API calls fail with 401"**
- JWT may be expired (clear localStorage)
- Token may not be properly set in headers
- Check AuthContext is wrapping the app

**"Photos not displaying**
- Verify backend is serving uploads: `http://localhost:8000/uploads/...`
- Check server.js has static file serving: `app.use('/uploads', express.static(...))`
- Re-upload student photos

## Production Deployment

Before deploying to production:

1. **Generate Strong Secrets**
   ```bash
   # Generate JWT secrets and API keys
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```

2. **Configure Environment Variables**
   - Use environment variables instead of .env file
   - Set NODE_ENV=production
   - Use real domain names for URLs

3. **Database**
   - Use production MySQL database
   - Configure backups
   - Use SSL for connections

4. **Frontend Build**
   ```bash
   cd frontend
   npm run build
   # Deploy build/ folder to hosting
   ```

5. **Backend Process Manager**
   - Use PM2 or systemd for process management
   - Enable auto-restart on crash

6. **Mini PC**
   - Run in systemd service
   - Use supervisor or similar for reliability

7. **Email**
   - Use production email service
   - Consider using SendGrid, AWS SES instead of Gmail

## Configured Credentials

Set `ADMIN_EMAIL` and a unique `ADMIN_PASSWORD` in `backend-node/.env`.

Set `PARENT_EMAIL` and a unique `PARENT_PASSWORD` in the same file.

The `seed.js` script creates those configured accounts. The project does not ship with default login credentials.
