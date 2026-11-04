# MySQL Integration for SCMCIES - Complete Guide

## 📦 What You Have

- `scmcies_mysql_dump.sql` - Ready-to-import MySQL database
- `database_migration.py` - Migration utility tool
- `XAMPP_MYSQL_SETUP.md` - XAMPP setup guide
- FastAPI backend configured for multiple databases

## 🚀 Quick Import (3 Steps)

### Step 1: Start XAMPP
```
Click XAMPP Control Panel → Start Apache & MySQL
```

### Step 2: Open phpMyAdmin
```
Go to: http://localhost/phpmyadmin
```

### Step 3: Import Database
1. Click "Import" tab
2. Click "Choose File"
3. Select: `scmcies_mysql_dump.sql`
4. Click "Go" ✅

**Done! Your database is now in MySQL!**

---

## 🔧 Configure Backend to Use MySQL

### Step 1: Create `.env` file

Create `backend/.env`:
```env
DATABASE_URL=mysql+pymysql://root@localhost/scmcies
DEBUG=True
SECRET_KEY=your-secret-key
```

### Step 2: Install MySQL Driver

```bash
cd backend
pip install pymysql cryptography
```

OR update all dependencies:
```bash
pip install -r requirements.txt
```

### Step 3: Restart Backend

```bash
# Windows
run.bat

# Linux/Mac
./run.sh
```

You should see:
```
✅ Default users created successfully
INFO: Uvicorn running on http://0.0.0.0:8000
```

---

## ✅ Verify It's Working

### Test 1: Check API Docs
```
http://localhost:8000/docs
```
Should show Swagger UI with all endpoints

### Test 2: Health Check
```bash
curl http://localhost:8000/health
```
Should return:
```json
{"status": "healthy"}
```

### Test 3: Test API
Use Python script:
```bash
python api_test.py
```

### Test 4: Check phpMyAdmin
```
http://localhost/phpmyadmin
Select Database: scmcies
Check tables and data
```

---

## 📊 Database File Overview

### scmcies_mysql_dump.sql

Contains:
```sql
-- CREATE DATABASE scmcies
-- CREATE TABLE users (4 default records)
-- CREATE TABLE students (5 sample records)
-- CREATE TABLE attendance_records (6 sample events)
-- CREATE VIEWS for easy queries
```

**Users Created:**
- admin@scmcies.com (Admin)
- parent1@example.com (Parent)
- parent2@example.com (Parent)
- parent3@example.com (Parent)

---

## 🔄 Advanced: Using Migration Tool

### Windows
```bash
python database_migration.py
```

### What it offers:
1. ✅ Validate SQLite database
2. ✅ Create backups
3. ✅ Export SQLite to SQL
4. ✅ Show MySQL credentials
5. ✅ Display migration guide

### Steps:
```
1. Start the script
2. Select option "5" for migration guide
3. Follow the steps
4. Or select "6" to run all validations
```

---

## 🔐 Configured Credentials

### MySQL Access
```
Host: localhost
Port: 3306
User: root
Password: (empty)
Database: scmcies
```

### API Users
```
Email: admin@scmcies.com
Password: your_configured_admin_password
Role: Admin
```

---

## 📋 Configuration Options

### Option 1: SQLite (Default)
```env
DATABASE_URL=sqlite:///./scmcies.db
```
- No additional setup
- Good for development
- Limited concurrent users

### Option 2: MySQL with XAMPP
```env
DATABASE_URL=mysql+pymysql://root@localhost/scmcies
```
- Setup with XAMPP (easiest)
- Better for small/medium use
- Local network only

### Option 3: MySQL with Password
```env
DATABASE_URL=mysql+pymysql://root:mypassword@localhost/scmcies
```
- After setting MySQL root password

### Option 4: Remote MySQL
```env
DATABASE_URL=mysql+pymysql://user:pass@remote-host.com/scmcies
```
- Production setup
- Cloud or dedicated server

### Option 5: PostgreSQL (Production)
```env
DATABASE_URL=postgresql://user:password@localhost/scmcies
```
- Better for large deployments
- More robust

---

## 📡 Troubleshooting

### Problem: "Can't connect to server"
**Solution:**
```bash
# Check MySQL running
# Windows: Check XAMPP Control Panel
# Linux: systemctl status mysql

# Restart MySQL
# Windows: In XAMPP, click Stop then Start
# Linux: sudo systemctl restart mysql
```

### Problem: "Access denied"
**Solution:**
```sql
-- Check MySQL user privileges
-- In phpMyAdmin SQL tab:
SELECT user, host FROM mysql.user WHERE db='scmcies';

-- Or rebuild from dump
mysql -u root -p scmcies < scmcies_mysql_dump.sql
```

### Problem: "Database already exists"
**Solution:**
```sql
-- Drop and recreate
DROP DATABASE IF EXISTS scmcies;
-- Then import fresh dump
```

### Problem: Backend can't connect
**Check:**
1. MySQL running? (XAMPP)
2. Database exists? (phpMyAdmin)
3. Correct DATABASE_URL in .env?
4. pymysql installed? (pip list | grep pymysql)

**Fix:**
```bash
# Reinstall driver
pip uninstall pymysql -y
pip install pymysql cryptography

# Restart backend
# run.bat or run.sh
```

---

## 🗄️ Table Structure

### users
```sql
id          INT (Primary Key)
email       VARCHAR (Unique)
password    VARCHAR (Hashed)
name        VARCHAR
user_type   ENUM (admin/parent)
created_at  DATETIME
```

### students
```sql
id             INT (Primary Key)
student_id     VARCHAR (Unique)
name           VARCHAR
grade          VARCHAR
parent_emails  LONGTEXT (Comma-separated)
face_data      LONGTEXT (Optional)
created_at     DATETIME
```

### attendance_records
```sql
id            INT (Primary Key)
student_id    VARCHAR
student_name  VARCHAR
grade         VARCHAR
status        ENUM (Inside Campus/Outside Campus)
timestamp     DATETIME
parent_emails LONGTEXT (Comma-separated)
```

---

## 🔍 Useful Queries

### Today's Attendance
```sql
SELECT student_name, status, timestamp
FROM attendance_records
WHERE DATE(timestamp) = CURDATE()
ORDER BY timestamp DESC;
```

### Students by Grade
```sql
SELECT COUNT(*) as count, grade
FROM students
GROUP BY grade;
```

### Parent's Children
```sql
SELECT name, grade, student_id
FROM students
WHERE FIND_IN_SET('parent1@example.com', parent_emails);
```

### Recent Activity
```sql
SELECT a.*, u.email, u.name
FROM attendance_records a
LEFT JOIN students s ON a.student_id = s.student_id
ORDER BY a.timestamp DESC
LIMIT 10;
```

---

## 📱 Backend Configuration

### app/core/config.py
- Automatically handles SQLite and MySQL
- No code changes needed
- Just update `.env`

### app/core/database.py
- SQLAlchemy ORM handles differences
- Works with any SQL database
- Connection pooling enabled

---

## 🚀 Production Deployment

### Recommended Setup:
1. Cloud Database (MySQL/PostgreSQL)
2. FastAPI on cloud server
3. Flutter app points to cloud API

### Example Production .env:
```env
DEBUG=False
DATABASE_URL=mysql+pymysql://scmcies_user:strong_password@db.example.com/scmcies
SECRET_KEY=generate-very-strong-secret-key-here
ALLOWED_ORIGINS=https://app.scmcies.com,https://admin.scmcies.com
```

---

## 🛡️ Backup & Recovery

### Daily Backup
```bash
mysqldump -u root scmcies > backup_$(date +%Y%m%d).sql
```

### Restore from Backup
```bash
mysql -u root scmcies < backup_20260305.sql
```

### Automated Backup Script
```bash
# Create backup_daily.sh
#!/bin/bash
DATE=$(date +\%Y\%m\%d)
BACKUPS_DIR="/backups/scmcies"
mkdir -p $BACKUPS_DIR
mysqldump -u root scmcies > $BACKUPS_DIR/scmcies_$DATE.sql
echo "Backup created: $BACKUPS_DIR/scmcies_$DATE.sql"

# Run daily with cron:
# 0 2 * * * /path/to/backup_daily.sh
```

---

## 🔗 Quick Links

- **XAMPP**: https://www.apachefriends.org
- **phpMyAdmin**: http://localhost/phpmyadmin
- **MySQL Docs**: https://dev.mysql.com/doc
- **FastAPI Docs**: http://localhost:8000/docs
- **SQLAlchemy**: https://docs.sqlalchemy.org

---

## ✨ What's Next

1. ✅ Import database using scmcies_mysql_dump.sql
2. ✅ Update backend .env with MySQL connection
3. ✅ Restart backend (run.bat/run.sh)
4. ✅ Test API at http://localhost:8000/docs
5. ✅ Run Flutter app
6. ✅ Login with configured credentials
7. ✅ Verify data syncs correctly

---

## 📞 Need Help?

Check these files:
- `XAMPP_MYSQL_SETUP.md` - XAMPP specific guide
- `INTEGRATION_GUIDE.md` - Full stack integration
- `QUICK_REFERENCE.md` - API quick reference
- `DATABASE_GUIDE.md` - SQLite guide
- `backend/README.md` - Backend documentation

---

**Your SCMCIES system is now using MySQL! 🎉**

All the same features work exactly the same way. The backend automatically handles the database transactions. Just keep your `.env` file updated with correct database credentials.

---

*Last updated: 2026-03-05*
*Documentation version: 1.0*
