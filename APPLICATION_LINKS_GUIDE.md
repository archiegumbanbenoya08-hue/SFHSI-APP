# 🔗 SCMCIES Application Links & Deployment Guide

## 📱 Application Access Links

### **Online Deployment**
- **Backend API**: `http://172.21.244.38:8000`
- **API Documentation**: `http://172.21.244.38:8000/docs`
- **Health Check**: `http://172.21.244.38:8000/health`

### **Local Testing**
- **Backend API**: `http://localhost:8000`
- **API Documentation**: `http://localhost:8000/docs`

---

## 🚀 Quick Start - Run Both Backend & Frontend

### **Option 1: Windows Batch Files (Easiest)**

#### Step 1: Start Backend
```bash
cd backend
run.bat
```
Or double-click `backend/run.bat`

**Expected Output:**
```
🚀 SCMCIES FastAPI Backend
================================
✅ Python found: Python 3.11.0
🎉 Starting FastAPI Server...
📍 API URL: http://172.21.244.38:8000
📖 Documentation: http://172.21.244.38:8000/docs
INFO:     Uvicorn running on http://0.0.0.0:8000
```

#### Step 2: Start Flutter App (in new terminal)
```bash
flutter run -d windows
# or for web:
flutter run -d chrome
```

---

### **Option 2: Manual Setup**

#### Start Backend:
```cmd
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

#### Start Flutter (in new terminal):
```cmd
cd ..
flutter run -d windows
# or: flutter run -d chrome (for web)
```

---

## 👥 Default User Accounts

### **Admin Account**
- **Email**: `admin@scmcies.com`
- **Password**: `your_configured_admin_password`
- **Role**: Admin
- **Access**: Full access to all features

### **Parent Accounts**
| Email | Password | Name |
|-------|----------|------|
| parent1@example.com | your_configured_parent_password | Parent One Parent |
| parent2@example.com | your_configured_parent_password | Parent Two Parent |
| parent3@example.com | your_configured_parent_password | Parent Three Parent |

---

## 📋 Feature Access by Role

### **Admin Features**
- ✅ View all students
- ✅ Manage attendance records
- ✅ View statistics & reports
- ✅ Manage user accounts
- ✅ System health monitoring

### **Parent Features**
- ✅ View children's information
- ✅ Check attendance records
- ✅ View grades & performance
- ✅ Receive notifications
- ✅ Update profile

---

## 🔍 Testing the Application

### 1. **Test Backend API**
Open browser and visit:
```
http://172.21.244.38:8000/docs
```
This opens **Swagger UI** where you can:
- Test all API endpoints
- View request/response schemas
- Authenticate with JWT tokens

### 2. **Test Flutter App Login**
Use provided credentials:
```
Email: parent1@example.com
Password: your_configured_parent_password
```

### 3. **Network Connectivity Check**
From any device on the same network:
```cmd
ping 172.21.244.38
```

---

## 🌐 Accessing from Other Devices

### From Another Computer on Same Network:

1. **Open Browser**:
   ```
   http://172.21.244.38:8000/docs
   ```

2. **Flutter Web (if deployed)**:
   ```
   http://172.21.244.38:3000
   ```

3. **Mobile Device** (Android):
   - Install Flutter app
   - Update API endpoint to `http://172.21.244.38:8000`
   - Run app

---

## 🔧 Configuration Files

### **Backend Configuration** (`backend/app/core/config.py`)
```python
# Server runs on all interfaces (0.0.0.0)
# Port: 8000
# Allowed Origins: All (change in production)
# Database: SQLite (scmcies.db)
```

### **Flutter Configuration** (`lib/services/api_client.dart`)
```dart
// API endpoint
static const String baseUrl = 'http://172.21.244.38:8000';
```

---

## 📊 API Endpoints

All endpoints are available at: `http://172.21.244.38:8000/docs`

### **Authentication**
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/logout` - User logout

### **Users**
- `GET /users/` - Get all users
- `GET /users/{user_id}` - Get user by ID
- `PUT /users/{user_id}` - Update user
- `DELETE /users/{user_id}` - Delete user

### **Students**
- `GET /students/` - Get all students
- `GET /students/{student_id}` - Get student by ID
- `POST /students/` - Create new student
- `PUT /students/{student_id}` - Update student

### **Statistics**
- `GET /stats/` - Get overall statistics
- `GET /stats/grade/{grade}` - Get grade statistics

---

## 🛡️ Security Notes

### **Current Setup** (Development)
- ⚠️ CORS is open to all origins
- ⚠️ Debug mode is enabled
- ⚠️ Secret key is hardcoded

### **Production Setup Recommended**
1. Change `secret_key` in `backend/app/core/config.py`
2. Set `debug = False`
3. Restrict `allowed_origins` to specific URLs
4. Use environment variables for sensitive data
5. Enable HTTPS/SSL certificates
6. Set strong database passwords

---

## ❌ Troubleshooting

### **Backend Won't Start**
```bash
# Check if port 8000 is in use
netstat -ano | findstr :8000

# Kill the process (if needed)
taskkill /PID <PID> /F

# Restart backend
cd backend
run.bat
```

### **Flutter App Can't Connect**
1. Verify backend is running
2. Check network access:
   ```bash
   ping 172.21.244.38
   ```
3. Ensure both devices are on same network
4. Update API URL in `lib/services/api_client.dart`

### **Port Already in Use**
Modify `backend/main.py` or startup script:
```python
# Change port from 8000 to custom port
uvicorn main:app --host 0.0.0.0 --port 9000
```

---

## 📱 Deployment Options

### **Option 1: Local Network** (Current Setup)
- ✅ Easy to set up
- ✅ Works on same network
- ❌ Not accessible from internet

### **Option 2: Cloud Deployment** (Recommended for Production)
- Use AWS, Google Cloud, Azure, or DigitalOcean
- Update API endpoint to cloud URL
- Set up HTTPS/SSL
- Configure proper security rules

### **Option 3: Docker Deployment**
- Containerize backend and frontend
- Deploy to Docker Hub or similar service
- Instructions in `BACKEND_SETUP.md`

---

## 📲 Mobile App Distribution

### **For Android Testing**
```bash
flutter build apk --release
# Share the .apk file with testers
```

### **For iOS Testing** (macOS only)
```bash
flutter build ios --release
# Generate TestFlight build for Apple testers
```

### **For Web Deployment**
```bash
flutter build web --release
# Deploy the build/web/ folder to hosting service
```

---

## 📞 Support Information

For issues or questions:
1. Check the `DATABASE_GUIDE.md` for database operations
2. Review `BACKEND_SETUP.md` for backend configuration
3. Check `INTEGRATION_GUIDE.md` for integration details
4. Contact: admin@scmcies.com

---

## ✅ Checklist Before Going Live

- [ ] Backend server is running on `http://172.21.244.38:8000`
- [ ] Flutter app can connect to backend
- [ ] Test login with all user types (Admin, Parent)
- [ ] Test attendance marking (Admin)
- [ ] Test viewing student data (Parent)
- [ ] Verify all features work correctly
- [ ] Test on multiple devices (same network)
- [ ] Document any security changes
- [ ] Create backup of database

---

**Last Updated**: March 11, 2026  
**Version**: 1.0  
**Developer**: SCMCIES Team
