# XAMPP MySQL Setup Checklist ✅

## 📥 Database Import (5 minutes)

- [ ] **XAMPP Started**
  - Open XAMPP Control Panel
  - Click "Start" button for:
    - [ ] Apache
    - [ ] MySQL

- [ ] **phpMyAdmin Opened**
  - Go to: http://localhost/phpmyadmin
  - You should see the phpMyAdmin interface

- [ ] **Database Imported**
  - Click "Import" tab
  - Click "Browse" / "Choose File"
  - Select: `scmcies_mysql_dump.sql`
  - Click "Go" button
  - Wait for "Import successful" message

- [ ] **Verify Import**
  - Left sidebar: Click `scmcies` database
  - You should see 3 tables:
    - [ ] users
    - [ ] students
    - [ ] attendance_records

---

## 🔧 Backend Configuration (3 minutes)

- [ ] **Create .env file**
  - Location: `backend/.env`
  - Copy from: `backend/.env.example`
  - Update DATABASE_URL to:
    ```env
    DATABASE_URL=mysql+pymysql://root@localhost/scmcies
    ```

- [ ] **Install MySQL Driver**
  - Open PowerShell/CMD in `backend` directory
  - Run: `pip install pymysql cryptography`
  - Or: `pip install -r requirements.txt`

- [ ] **Check installation**
  - Run: `pip list | find "pymysql"`
  - Should show: `pymysql  1.1.0` (or similar)

---

## 🚀 Start Backend (2 minutes)

- [ ] **Run Backend**
  - Windows: Double-click `backend/run.bat`
  - Or: Open PowerShell, cd backend, then `run.bat`
  - Expected output:
    ```
    🎉 Starting FastAPI Server...
    📍 API URL: http://localhost:8000
    ✅ Default users created successfully
    INFO: Uvicorn running on http://0.0.0.0:8000
    ```

- [ ] **Backend Running Verification**
  - Open browser: http://localhost:8000/health
  - Should show: `{"status": "healthy"}`

---

## 📖 API Documentation

- [ ] **View API Docs**
  - Open: http://localhost:8000/docs
  - You should see Swagger UI with all endpoints
  - Test an endpoint (e.g., health check)

---

## 🧪 Test API (2 minutes)

### Option A: Python Test Script
```bash
python api_test.py
```
Should show all tests as ✅ passing

### Option B: Use Swagger UI
- Go to: http://localhost:8000/docs
- Try: `GET /health` → "Execute"
- Try: `POST /auth/login`
  - Email: `admin@scmcies.com`
  - Password: `your_configured_admin_password`
  - Should return access_token

- [ ] **Test Results**
  - [ ] Health check works
  - [ ] Login successful
  - [ ] Got JWT token

---

## 📱 Update Flutter App (1 minute)

- [ ] **Update API Client**
  - File: `lib/services/api_client.dart`
  - Verify baseUrl:
    ```dart
    static const String baseUrl = 'http://localhost:8000';
    ```

- [ ] **Install HTTP Package**
  - Run: `flutter pub get`
  - Should see: `http` package installed

---

## ✅ Verify MySQL is Connected

### In phpMyAdmin:
- [ ] Click `scmcies` database
- [ ] See 3 tables with data
- [ ] If you see new records after API tests, MySQL is connected! ✅

### Check Database Activity:
```sql
-- Run in phpMyAdmin SQL tab:
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM students;
SELECT COUNT(*) FROM attendance_records;
```

---

## 🎯 Final Verification

- [ ] XAMPP MySQL Running
- [ ] Database imported in phpMyAdmin
- [ ] Backend .env configured
- [ ] Backend running at http://localhost:8000
- [ ] API docs available at http://localhost:8000/docs
- [ ] Can login with admin@scmcies.com / your_configured_admin_password
- [ ] Flutter app can connect to backend

---

## 🚀 Ready to Go!

Once all checkboxes are ✅, your system is ready:

**Running:**
- ✅ XAMPP MySQL Server
- ✅ FastAPI Backend (http://localhost:8000)
- ✅ Flutter App (can now run)

**Next Step:**
```bash
flutter run
```

---

## 🆘 If Something Goes Wrong

### Backend won't start:
- [ ] Check XAMPP MySQL is running
- [ ] Check `backend/.env` has correct DATABASE_URL
- [ ] Check pymysql installed: `pip install pymysql`
- [ ] Check database exists in phpMyAdmin
- [ ] Check no port conflicts on 8000

### Can't access phpMyAdmin:
- [ ] Check XAMPP is started
- [ ] Go to: http://localhost/phpmyadmin
- [ ] Check Apache is running in XAMPP panel

### Database not found:
- [ ] Re-import: scmcies_mysql_dump.sql
- [ ] Use phpMyAdmin Import tab
- [ ] Verify it created 3 tables

### API returns 500 error:
- [ ] Check backend console for errors
- [ ] Check MySQL is running
- [ ] Restart backend

---

## 📊 Success Indicators

You'll know everything is working when:

✅ Browser shows API docs at http://localhost:8000/docs
✅ Can login via Swagger UI with configured credentials
✅ phpMyAdmin shows data in all 3 tables
✅ Flutter app connects and loads data
✅ No error messages in backend console

---

## 📞 Reference Files

If you need help, check:
- `XAMPP_MYSQL_SETUP.md` - Detailed setup instructions
- `MYSQL_INTEGRATION.md` - MySQL configuration guide
- `QUICK_REFERENCE.md` - API quick reference
- `INTEGRATION_GUIDE.md` - Full stack integration
- `backend/README.md` - Backend documentation

---

## ⏱️ Total Time Required

- Database Import: **5 minutes**
- Backend Setup: **5 minutes**
- Testing: **5 minutes**

**Total: ~15 minutes** ⏱️

---

## 🎉 Congratulations!

Your SCMCIES system is now running on:
- **Frontend**: Flutter (Mobile/Web)
- **Backend**: FastAPI (REST API)
- **Database**: MySQL (XAMPP)

Everything is configured and ready to go! 🚀

---

*Last Updated: 2026-03-05*
*Setup Time: ~15 minutes*
*Difficulty: Easy ⭐⭐*
