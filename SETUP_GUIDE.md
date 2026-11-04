# SCMCIES System - Complete Setup Guide

## Quick Start

### Option 1: PowerShell Script (Recommended for Windows 10/11)
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup-and-run.ps1
```

### Option 2: Batch File (Classic Windows)
```cmd
setup-and-run.bat
```

---

## Prerequisites

Before running the setup script, ensure you have installed:

### 1. **Node.js & npm**
- Download: https://nodejs.org/ (LTS version recommended)
- Verify installation:
  ```cmd
  node --version
  npm --version
  ```
- **Add to PATH**: Node.js installer should do this automatically

### 2. **MySQL Server**
- Download: https://dev.mysql.com/downloads/mysql/
- Install and start the service
- Verify installation:
  ```cmd
  mysql --version
  mysql -u root (should connect without password if default setup)
  ```

### 3. **Python 3.8+**
- Download: https://www.python.org/downloads/
- **Important**: Check "Add Python to PATH" during installation
- Verify installation:
  ```cmd
  python --version
  pip --version
  ```

---

## Step-by-Step Manual Setup

If scripts don't work, follow these steps manually:

### Step 1: Setup Database
```cmd
mysql -u root < backend-node\schema.sql
```

If you have MySQL password:
```cmd
mysql -u root -p < backend-node\schema.sql
```

### Step 2: Configure Environment Files

Copy the example files:
```cmd
copy backend-node\.env.example backend-node\.env
copy frontend\.env.example frontend\.env
copy mini_pc_client\.env.example mini_pc_client\.env
```

Edit them if needed (API URLs, credentials).

### Step 3: Install Dependencies

Backend:
```cmd
cd backend-node
npm install
cd ..
```

Frontend:
```cmd
cd frontend
npm install
cd ..
```

Mini PC Client:
```cmd
cd mini_pc_client
pip install -r requirements.txt
cd ..
```

### Step 4: Seed Admin Account

```cmd
cd backend-node
node seed.js
cd ..
```

Output should show:
```
Admin account created successfully
Parent account created successfully
```

### Step 5: Start All Services

Open 3 separate command prompts and run:

**Terminal 1 - Backend API:**
```cmd
cd backend-node
npm start
```
Should show: `Server running at http://localhost:8000`

**Terminal 2 - Frontend:**
```cmd
cd frontend
npm start
```
Should show: `webpack compiled` and open http://localhost:3000

**Terminal 3 - Mini PC Client:**
```cmd
cd mini_pc_client
python main.py
```
Should show: `Initializing face recognition...`

---

## Troubleshooting

### MySQL Command Not Found
Installation: https://dev.mysql.com/downloads/mysql/
```cmd
# Test connection
mysql -u root
```

### npm/node Command Not Found
- Reinstall Node.js: https://nodejs.org/
- Restart your terminal after installation
- Check PATH: `echo %PATH%` should include Node.js directory

### Python Command Not Found
- Reinstall Python: https://www.python.org/downloads/
- **Check "Add Python to PATH"** during installation
- Restart terminal after installation

### pip install Fails for face_recognition
This package requires build tools. Install:
- **Windows**: Microsoft Build Tools for Visual Studio
- https://visualstudio.microsoft.com/downloads/
- Select "C++ build tools" during installation

### MySQL Connection Refused
```cmd
# Start MySQL service (Windows)
net start MySQL80

# Or check if running
tasklist | findstr mysql
```

### Ports Already in Use
- Backend on 8000: Check `lsof -i :8000` (or `netstat -ano | findstr :8000` on Windows)
- Frontend on 3000: Kill the process and restart
- Mini PC: Uses webcam, no port conflict

---

## Verification Checklist

After setup, verify:

- [ ] Backend API running: http://localhost:8000
- [ ] Frontend accessible: http://localhost:3000
- [ ] Can login as Admin: admin@scmcies.com / your_configured_admin_password
- [ ] Can login as Parent: parent@example.com / your_configured_parent_password
- [ ] Webcam window appears for Mini PC client
- [ ] Database tables created: `mysql -u root -e "SHOW TABLES FROM face_recognition_system;"`

---

## Configured Credentials

```
Admin Account:
  Email: admin@scmcies.com
  Password: your_configured_admin_password

Parent Account:
  Email: parent@example.com
  Password: your_configured_parent_password
```

---

## Services Overview

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| Backend API | 8000 | http://localhost:8000 | Node.js/Express REST API |
| Frontend | 3000 | http://localhost:3000 | React Dashboard (Admin/Parent) |
| Mini PC | N/A | Webcam | Face Recognition & Detection |
| MySQL | 3306 | localhost:3306 | Student/Log Database |

---

## Important Files

- `backend-node/schema.sql` - Database schema
- `backend-node/seed.js` - Initial admin account setup
- `backend-node/main.py` - NOT NEEDED (Python Flask removed)
- `mini_pc_client/main.py` - Face recognition client
- `frontend/src/App.jsx` - React application entry

---

## System Architecture

```
┌─────────────────────────────────────────┐
│      React Frontend (Port 3000)         │
│  Admin Dashboard | Parent Dashboard     │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│     Node.js Backend API (Port 8000)     │
│  Auth | Students | Logs | Parents       │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│  MySQL Database (Port 3306)             │
│  admin | parent | student | entry_log   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│   Python Mini PC Client (Webcam)        │
│   Face Recognition & Entry/Exit Logging │
└─────────────────────────────────────────┘
```

---

## FAQ

### Q: Can I change the admin password?
A: After login, update it manually in the database:
```cmd
mysql -u root -e "UPDATE face_recognition_system.admin SET password='YOUR_HASH' WHERE admin_id=1;"
```
(Requires bcrypt hashing - easier to edit via API)

### Q: Where are student photos stored?
A: In `backend-node/uploads/students/` directory

### Q: How do I add more students?
A: Use Admin Dashboard > Students > Register New Student, or:
```cmd
# Via API
curl -X POST http://localhost:8000/api/students \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "first_name=John" \
  -F "last_name=Doe" \
  -F "grade_level=10" \
  -F "section=A" \
  -F "parent_email=parent@example.com" \
  -F "photo=@path/to/photo.jpg"
```

### Q: How do I reset the database?
A: Drop and recreate:
```cmd
mysql -u root -e "DROP DATABASE face_recognition_system;"
mysql -u root < backend-node\schema.sql
cd backend-node && node seed.js
```

---

## Support

For issues:
1. Check error messages in terminal windows
2. Ensure all prerequisites installed
3. Verify MySQL is running: `mysql -u root`
4. Check ports: `netstat -ano`
5. Review logs in service windows

