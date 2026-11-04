# 🌐 SCMCIES Web Application - Direct Access Guide

## **📍 Direct Application Links**

### **Access the Application Instantly**

Simply click or visit these links to access the SCMCIES application directly in your browser:

#### **Login Page** (Start Here)
```
http://172.21.244.38:8000/
```
or
```
http://172.21.244.38:8000/login
```

#### **Dashboard** (After Login)
```
http://172.21.244.38:8000/dashboard
```

#### **API Documentation** (For Developers)
```
http://172.21.244.38:8000/docs
```

---

## 🚀 **How to Use - Step by Step**

### **Step 1: Make Sure Backend is Running**

Start the backend server:
```bash
cd backend
run.bat
```

You should see:
```
🎉 Starting FastAPI Server...
📍 Network Access URL: http://172.21.244.38:8000
```

### **Step 2: Open Your Browser**

Click one of these links or copy-paste into your browser:
- **For Login**: `http://172.21.244.38:8000/`
- **For Dashboard**: `http://172.21.244.38:8000/dashboard`

### **Step 3: Login with Your Credentials**

#### **Admin Users**
- **Email**: `admin@scmcies.com`
- **Password**: `your_configured_admin_password`
- **Features**: Manage students, attendance, grades, statistics

#### **Parent Users**
- **Email**: `parent1@example.com`
- **Password**: `your_configured_parent_password`
- **Email**: `parent2@example.com`
- **Password**: `your_configured_parent_password`
- **Email**: `parent3@example.com`
- **Password**: `your_configured_parent_password`
- **Features**: View children's info, attendance, grades

### **Step 4: Explore Dashboard**

After logging in, you'll see:
- ✅ Personalized welcome message
- 📊 System statistics & analytics
- 🔧 Role-specific features
- 📋 Student/Children information
- ⚙️ Account settings

---

## 🎯 **Feature Overview by Role**

### **👨‍💼 Admin Dashboard Features**

1. **📊 Statistics Dashboard**
   - View total students
   - View total users
   - System health status

2. **📝 Manage Students**
   - Add new students
   - Edit student information
   - View student list

3. **✅ Mark Attendance**
   - Record daily attendance
   - Generate attendance reports
   - Track patterns

4. **📊 View Reports**
   - Statistics by grade
   - Performance analytics
   - Attendance trends

5. **👥 Manage Users**
   - Create admin accounts
   - Manage parent accounts
   - Set user roles

### **👨‍👩‍👧 Parent Dashboard Features**

1. **👶 View Children**
   - See enrolled children
   - View child information
   - Check enrollment status

2. **✅ Attendance Records**
   - Check daily attendance
   - View attendance history
   - Track absence patterns

3. **📈 Academic Performance**
   - View grades
   - Monitor academic progress
   - See performance trends

4. **⚙️ Account Settings**
   - Update profile
   - Change password
   - Update contact information

---

## 🔐 **Login Page Features**

### **Quick Demo Accounts**
The login page includes quick-click demo accounts:
- Just click on a demo account
- Credentials auto-fill
- Click Login button

### **Error Handling**
- Invalid credentials show clear error messages
- System status indicator (🟢 Online / 🔴 Offline)
- Helpful hints for common issues

### **Responsive Design**
- Works on desktop browsers
- Works on tablet browsers
- Mobile-friendly interface

---

## 📱 **Access Methods**

### **Method 1: Direct Browser Link** (Easiest)
```
Open any browser and visit:
http://172.21.244.38:8000/
```

### **Method 2: Create Bookmark**
1. Visit `http://172.21.244.38:8000/`
2. Press `Ctrl+D` (Windows) or `Cmd+D` (Mac)
3. Save bookmark
4. Click bookmark anytime to access

### **Method 3: Mobile/Tablet**
1. On same network
2. Visit `http://172.21.244.38:8000/` on phone
3. Works on iOS Safari, Android Chrome, etc.

### **Method 4: Share with Others**
Send this link to admin/parent users:
```
http://172.21.244.38:8000/
```
They can access from any device on your network!

---

## ✅ **Quick Verification Checklist**

### **Before First Use**
- [ ] Backend server is running (`backend/run.bat`)
- [ ] You can see "🎉 Starting FastAPI Server..." in terminal
- [ ] Browser shows no "Connection refused" error

### **Login Test**
- [ ] Can visit `http://172.21.244.38:8000/`
- [ ] Can see login form with email/password fields
- [ ] Can see demo account options
- [ ] System shows 🟢 Online indicator

### **Feature Access**
- [ ] Can login with test credentials
- [ ] Dashboard loads after login
- [ ] Can see role-specific features
- [ ] Student/Children table displays data

---

## 🔗 **All Available URLs**

| URL | Purpose | Access |
|-----|---------|--------|
| `http://172.21.244.38:8000/` | Login Page | Everyone |
| `http://172.21.244.38:8000/login` | Login Page (Alt) | Everyone |
| `http://172.21.244.38:8000/dashboard` | Dashboard | After Login |
| `http://172.21.244.38:8000/docs` | API Docs (Swagger) | Developers |
| `http://172.21.244.38:8000/redoc` | API Docs (ReDoc) | Developers |
| `http://172.21.244.38:8000/health` | Health Check | API |

---

## ❌ **Troubleshooting**

### **"Connection refused" Error**

**Cause**: Backend server not running

**Solution**:
```bash
cd backend
run.bat
# Wait for: 🎉 Starting FastAPI Server...
```

### **Page Shows "Cannot reach server"**

**Cause**: Backend is not running or URL is incorrect

**Solution**:
1. Check backend is running: `backend/run.bat`
2. Try: `http://localhost:8000/` (if on same computer)
3. Try: `http://172.21.244.38:8000/` (if on network)
4. Check firewall is not blocking port 8000

### **Login Page Loads But Login Fails**

**Cause**: Database might not have test accounts

**Solution**:
1. Stop backend: `Ctrl+C`
2. Delete `backend/scmcies.db` (if it exists)
3. Restart backend: `run.bat`
4. Try login again (database will reinitialize)

### **Can't Access from Other Devices**

**Cause**: Network connectivity or firewall issue

**Solution**:
1. Verify IP address: `ipconfig | findstr IPv4`
2. Use correct IP in link: `http://[YOUR-IP]:8000/`
3. Check firewall allows port 8000
4. Both devices must be on same network
5. Test with: `ping 172.21.244.38`

### **Dashboard Shows Random Data**

**Cause**: Using shared test database

**Solution**:
- Expected in demo/development mode
- Each login account shows appropriate data
- Use different accounts to see data separation

---

## 🔒 **Security & Privacy Notes**

### **Current Setup (Development)**
⚠️ This is for local network use only
- ✅ Good for testing and development
- ⚠️ Not suitable for internet deployment
- ⚠️ Passwords are basic security

### **For Production Deployment**
- [ ] Get SSL/HTTPS certificate
- [ ] Change default passwords
- [ ] Use a domain name (not IP address)
- [ ] Set CORS to specific origins
- [ ] Enable rate limiting
- [ ] Set strong secret keys
- [ ] Regular backups
- [ ] Monitor access logs

---

## 📞 **Support & Resources**

### **Documentation**
- `APPLICATION_LINKS_GUIDE.md` - Full deployment guide
- `LINKS_QUICK_REFERENCE.md` - Quick reference card
- `DATABASE_GUIDE.md` - Database operations
- `BACKEND_SETUP.md` - Backend configuration
- `INTEGRATION_GUIDE.md` - Full integration guide

### **Common Issues**
1. **Port already in use**: Change port in `backend/run.bat`
2. **Database locked**: Delete `scmcies.db` and restart
3. **CORS errors**: Already configured in `backend/app/core/config.py`
4. **Slow performance**: Normal for SQLite, consider PostgreSQL for production

---

## 🎉 **Quick Links Summary**

**Share this link with Admin:**
```
http://172.21.244.38:8000/
```

**Share this link with Parents:**
```
http://172.21.244.38:8000/
```

**Admin Test Credentials:**
```
Email: admin@scmcies.com
Password: your_configured_admin_password
```

**Parent Test Credentials:**
```
Email: parent1@example.com
Password: your_configured_parent_password
```

---

## 📝 **Session & Storage**

### **How Data Is Stored**
- **Local Storage**: Auth token stored in browser
- **Server Session**: User session maintained on backend
- **Database**: All data persisted in SQLite
- **Auto-logout**: Session expires after 30 minutes of inactivity

### **Clear Cache/Cookies**
If experiencing issues:
1. Press `Ctrl+Shift+Delete` (Windows)
2. Select "All time" / "Cached images and files"
3. Click "Clear data"
4. Try login again

---

**Last Updated**: March 11, 2026  
**Version**: 1.0  
**Status**: Web Application Ready for Use ✅
