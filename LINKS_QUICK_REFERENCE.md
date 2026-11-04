# 🔗 SCMCIES Application Links - Quick Reference Card

## 📍 Application URL Links

### **Network Access (For Admin & Parent Users)**
```
BACKEND API:      http://172.21.244.38:8000
API DOCS:         http://172.21.244.38:8000/docs
HEALTH CHECK:     http://172.21.244.38:8000/health
```

### **Local Testing**
```
BACKEND API:      http://localhost:8000
API DOCS:         http://localhost:8000/docs
```

---

## 🚀 Quick Start (3 Steps)

### **Step 1: Start Backend Server**
```
Option A (Easy): Double-click backend/run.bat
Option B (Manual): 
  cd backend
  python -m venv venv
  venv\Scripts\activate
  pip install -r requirements.txt
  python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

### **Step 2: Start Flutter Application** (in new terminal)
```
Option A (Easy): Double-click start_flutter_app.bat
Option B (Manual): 
  flutter run -d windows
  # or: flutter run -d chrome (for web)
```

### **Step 3: Login with Credentials**
```
ADMIN:
  Email:    admin@scmcies.com
  Password: your_configured_admin_password

PARENT:
  Email:    parent1@example.com
  Password: your_configured_parent_password
```

---

## 👥 All Test Accounts

| Role   | Email | Password |
|--------|-------|----------|
| Admin  | admin@scmcies.com | your_configured_admin_password |
| Parent | parent1@example.com | your_configured_parent_password |
| Parent | parent2@example.com | your_configured_parent_password |
| Parent | parent3@example.com | your_configured_parent_password |

---

## 📱 Access Methods

### **1. Web Browser (Recommended for Quick Testing)**
```
1. Open browser
2. Visit: http://172.21.244.38:8000/docs
3. Use Swagger UI to test endpoints
4. Or use: http://172.21.244.38:8000/admin (if admin panel available)
```

### **2. Flutter Mobile App**
```
1. Make sure backend is running
2. Run: flutter run -d windows
   or: flutter run -d chrome
3. App connects to: http://172.21.244.38:8000
4. Login with credentials
```

### **3. From Another Computer (Same Network)**
```
1. Ensure backend is running on this machine
2. On other computer, open browser
3. Visit: http://172.21.244.38:8000
4. Or use: curl http://172.21.244.38:8000/health
```

---

## ✅ Verification Checklist

- [ ] Backend server is running
  ```bash
  # Test with: curl http://172.21.244.38:8000/health
  # Expected response: {"status": "healthy"}
  ```

- [ ] Flutter app connects to backend
  - No connection errors in console
  - Login page loads without errors

- [ ] Can login with test accounts
  - Try: parent1@example.com / your_configured_parent_password

- [ ] Can view app features
  - Admin can see student list
  - Parent can see children info

---

## 🔧 Common Commands

### **Check if backend is running:**
```bash
curl http://172.21.244.38:8000/health
# or use browser: http://172.21.244.38:8000/health
```

### **View API documentation:**
```bash
# Open in browser:
http://172.21.244.38:8000/docs
```

### **Stop backend server:**
```bash
# In terminal: Press Ctrl+C
```

### **Check what's using port 8000:**
```bash
netstat -ano | findstr :8000
```

### **Kill process on port 8000:**
```bash
taskkill /PID <PID_NUMBER> /F
```

---

## 📊 API Endpoint Summary

All endpoints tested in: `http://172.21.244.38:8000/docs`

### **Auth Endpoints**
- `POST /auth/login` - Login
- `POST /auth/register` - Register
- `POST /auth/logout` - Logout

### **Users**
- `GET /users/` - Get all users
- `GET /users/{id}` - Get user by ID
- `POST /users/` - Create user
- `PUT /users/{id}` - Update user
- `DELETE /users/{id}` - Delete user

### **Students**
- `GET /students/` - Get all students
- `GET /students/{id}` - Get student
- `POST /students/` - Create student
- `PUT /students/{id}` - Update student

### **Statistics**
- `GET /stats/` - Get overall stats
- `GET /stats/grade/{grade}` - Get grade stats

---

## 🎯 Feature Access

### **Admin Dashboard**
- ✅ All students list
- ✅ Mark attendance
- ✅ Grade management
- ✅ Statistics & reports
- ✅ User management

### **Parent Dashboard**
- ✅ View children info
- ✅ Check attendance
- ✅ View grades
- ✅ Receive notifications
- ✅ Update profile

---

## ❓ Troubleshooting

### **"Connection refused" error**
- Backend server not running
- Solution: Start backend with `backend/run.bat`

### **"Port 8000 already in use"**
```bash
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

### **Flutter app crashes on startup**
- Backend not running
- Wrong API URL in `lib/services/api_client.dart`
- Check console for error messages

### **Can't connect from another device**
- Check both devices are on same network
- Run: `ping 172.21.244.38` from other device
- Firewall might be blocking port 8000

---

## 📱 Device Network IP

**This Machine Network IP**: `172.21.244.38`

**To access from other devices:** `http://172.21.244.38:8000`

To find your machine's IP:
```bash
ipconfig | findstr IPv4
```

---

## 🔐 Security Notes

⚠️ **Current Setup is for Development Only**

For Production:
- [ ] Change secret key in `backend/app/core/config.py`
- [ ] Set `debug = False`
- [ ] Restrict CORS origins
- [ ] Use HTTPS/SSL
- [ ] Strong database passwords
- [ ] Regular backups

---

## 📞 Quick Links

- [Flutter Documentation](https://flutter.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [API Docs (Swagger)](http://172.21.244.38:8000/docs)
- Database Guide: `DATABASE_GUIDE.md`
- Integration Guide: `INTEGRATION_GUIDE.md`

---

**Last Updated**: March 11, 2026  
**Version**: 1.0
