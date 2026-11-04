# XAMPP MySQL Setup Guide for SCMCIES

## 📥 How to Import Database into XAMPP

### Method 1: Using phpMyAdmin (Easiest)

1. **Start XAMPP**
   - Open XAMPP Control Panel
   - Click "Start" for Apache and MySQL

2. **Open phpMyAdmin**
   - Go to: http://localhost/phpmyadmin
   - Default login: 
     - Username: `root`
     - Password: (leave empty)

3. **Import the Database**
   - Click "Import" tab at the top
   - Click "Choose File" button
   - Select `scmcies_mysql_dump.sql`
   - Click "Go" button
   - Wait for completion ✅

### Method 2: Using Command Line

1. **Open Command Prompt/PowerShell**
   - Press `Win + R`
   - Type `cmd` and press Enter

2. **Navigate to MySQL bin directory**
   ```bash
   cd "C:\xampp\mysql\bin"
   ```

3. **Import the database**
   ```bash
   mysql -u root -p scmcies < "C:\Users\Admin\Desktop\SCMCIES APP\scmcies_mysql_dump.sql"
   ```
   - Press Enter
   - Leave password empty (just press Enter)

4. **Verify import**
   ```bash
   mysql -u root
   USE scmcies;
   SHOW TABLES;
   SELECT COUNT(*) FROM users;
   ```

### Method 3: Using MySQL Workbench

1. Open MySQL Workbench
2. Connect to local MySQL server
3. File → Open SQL Script
4. Select `scmcies_mysql_dump.sql`
5. Execute (Ctrl + Shift + Enter)

## ✅ Verify Database Import

### Check in phpMyAdmin
1. Left sidebar → Select `scmcies` database
2. You should see 2 tables:
   - `students`
   - `users`

### Check with SQL Query
```sql
-- Count records
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_students FROM students;
```

Expected output:
- 4 users (3 parents + 1 admin)
- 5 sample students

## 🔐 Configured Credentials

| Email | Password | Role | Note |
|-------|----------|------|------|
| admin@scmcies.com | your_configured_admin_password | Admin | Change after setup |
| parent1@example.com | your_configured_parent_password | Parent | Configured account |
| parent2@example.com | your_configured_parent_password | Parent | Configured account |
| parent3@example.com | your_configured_parent_password | Parent | Configured account |

## ⚠️ Important: Update Password Hashes

The SQL file contains placeholder password hashes. To use real passwords:

### Option 1: Generate Proper Hashes

Using Python (with bcrypt):
```python
import bcrypt

password = "your_configured_parent_password"
hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(12))
print(hashed.decode('utf-8'))
```

### Option 2: Use Backend to Create Users

1. Start the FastAPI backend
2. Use the `/auth/register` endpoint
3. Let the backend handle password hashing
4. Export from backend database to MySQL

## 🔧 Update Backend Configuration

To use MySQL instead of SQLite:

### Edit `backend/.env`
```env
# Change from SQLite to MySQL
DATABASE_URL=mysql+pymysql://root@localhost/scmcies

# Or with password (if set)
DATABASE_URL=mysql+pymysql://root:password@localhost/scmcies
```

### Install MySQL driver
```bash
cd backend
pip install pymysql
pip install -r requirements.txt
```

### Update `backend/app/core/database.py`
```python
# Change connection args
engine = create_engine(
    settings.database_url,
    # Remove check_same_thread for MySQL
)
```

## 📋 Database Tables Overview

### `users` Table
```sql
- id (INT) - Primary key
- email (VARCHAR) - Unique email
- password (VARCHAR) - Hashed password
- name (VARCHAR) - User full name
- user_type (ENUM) - 'admin' or 'parent'
- created_at (DATETIME) - Account creation time
```

### `students` Table
```sql
- id (INT) - Primary key
- student_id (VARCHAR) - Unique student ID
- name (VARCHAR) - Student name
- grade (VARCHAR) - Grade level
- parent_emails (LONGTEXT) - Comma-separated parent emails
- face_data (LONGTEXT) - Face embedding reference
- created_at (DATETIME) - Record creation time
```

### `attendance_records` Table
```sql
- id (INT) - Primary key
- student_id (VARCHAR) - Reference to student
- student_name (VARCHAR) - Student name (denormalized)
- grade (VARCHAR) - Grade level (denormalized)
- status (ENUM) - 'Inside Campus' or 'Outside Campus'
- timestamp (DATETIME) - Event timestamp
- parent_emails (LONGTEXT) - Parent emails to notify
```

## 🔍 Useful SQL Queries

### Get today's attendance count
```sql
SELECT 
    COUNT(*) as total_events,
    SUM(CASE WHEN status = 'Inside Campus' THEN 1 ELSE 0 END) as inside,
    SUM(CASE WHEN status = 'Outside Campus' THEN 1 ELSE 0 END) as outside
FROM attendance_records
WHERE DATE(timestamp) = CURDATE();
```

### Get student attendance history
```sql
SELECT * FROM attendance_records
WHERE student_id = 'STU001'
ORDER BY timestamp DESC
LIMIT 10;
```

### Get current status of all students
```sql
SELECT 
    student_id,
    student_name,
    grade,
    MAX(timestamp) as last_event,
    (SELECT status FROM attendance_records ar2 
     WHERE ar2.student_id = attendance_records.student_id 
     ORDER BY timestamp DESC LIMIT 1) as current_status
FROM attendance_records
GROUP BY student_id, student_name, grade;
```

### Get parents and their children
```sql
SELECT 
    u.email,
    u.name as parent_name,
    s.student_id,
    s.name as student_name,
    s.grade
FROM users u
JOIN students s ON FIND_IN_SET(u.email, s.parent_emails)
WHERE u.user_type = 'parent'
ORDER BY u.name, s.name;
```

## 🔄 Syncing Between SQLite and MySQL

### Export from SQLite to MySQL

1. **Export from SQLite**
   ```bash
   sqlite3 scmcies.db ".dump" > sqlite_dump.sql
   ```

2. **Convert to MySQL format**
   - Edit the dump file, remove SQLite-specific syntax
   - Or use online converter

3. **Import to MySQL**
   ```bash
   mysql -u root -p scmcies < mysql_dump.sql
   ```

### Export from MySQL to SQLite

```bash
# Generate MySQL dump
mysqldump -u root scmcies > mysql_dump.sql

# Import to SQLite
sqlite3 scmcies.db < mysql_dump.sql
```

## 🛡️ Backup Database

### Backup MySQL
```bash
# Backup single database
mysqldump -u root scmcies > backup_scmcies.sql

# Backup with data only (no schema)
mysqldump -u root -d scmcies > backup_schema.sql
```

### Restore from Backup
```bash
mysql -u root scmcies < backup_scmcies.sql
```

## 📱 Connect Flutter/Backend to MySQL

### Update FastAPI Backend

1. Install MySQL driver:
   ```bash
   pip install pymysql
   ```

2. Update `.env`:
   ```env
   DATABASE_URL=mysql+pymysql://root@localhost/scmcies
   ```

3. Restart backend

### Update Flutter (if needed)
- No changes needed - communicates via API
- API automatically uses configured database

## ✨ Sample Data for Testing

The SQL file includes:
- **4 Users**: 3 parents + 1 admin
- **5 Students**: Distributed grades 4-6
- **6 Attendance Records**: Mix of inside/outside campus events

## 🚀 Next Steps

1. ✅ Import database using one of the methods above
2. ✅ Verify tables and data in phpMyAdmin
3. ✅ Update password hashes (optional but recommended)
4. ✅ Update backend configuration to use MySQL
5. ✅ Restart FastAPI backend
6. ✅ Test with Flutter app

## 🐛 Troubleshooting

### "Database already exists"
- All data will be preserved
- Or drop first: `DROP DATABASE scmcies;`

### "Access denied for user"
- Use correct credentials
- Windows: username is usually `root` with empty password
- Linux/Mac: might need `sudo`

### "MySQL is not running"
- Start XAMPP and click "Start" for MySQL
- Or use Services: `net start MySQL80` (Windows)

### "Port 3306 already in use"
- Change MySQL port in XAMPP config
- Or stop other MySQL instances

### Import fails
- Check file encoding (should be UTF-8)
- Check file path has no special characters
- Try importing in smaller sections

## 📞 Support

- XAMPP: https://www.apachefriends.org/
- phpMyAdmin: https://www.phpmyadmin.net/
- MySQL: https://www.mysql.com/
- FastAPI + MySQL: Check [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)

---

**Database setup complete!** You now have SCMCIES running on XAMPP MySQL. 🎉
