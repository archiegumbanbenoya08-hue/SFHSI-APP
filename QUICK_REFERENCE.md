# FastAPI + Flutter Quick Reference

## 🚀 Startup

### Start Backend
```bash
cd backend
# Windows
run.bat

# Linux/Mac
chmod +x run.sh
./run.sh
```

### Start Flutter
```bash
flutter run
```

### Test API
```bash
python api_test.py
# or visit http://localhost:8000/docs
```

## 📡 API Base URL

```dart
// Development
static const String baseUrl = 'http://localhost:8000';

// Android Emulator
static const String baseUrl = 'http://10.0.2.2:8000';

// Production
static const String baseUrl = 'https://api.yourdomain.com';
```

## 🔐 Authentication

### Login
```dart
final response = await ApiClient.login(
  'user@example.com',
  'password123'
);
// ApiClient.authToken is set automatically
```

### Get Current User
```dart
final user = await ApiClient.getCurrentUser();
// User has: id, email, name, user_type, created_at
```

### Update Profile
```dart
await ApiClient.updateProfile(
  name: 'New Name',
  password: null  // Optional
);
```

### Logout
```dart
ApiClient.logout();  // Clear token
```

## 👥 Students

### List Students
```dart
// Parents see only their children
// Admins see all students
final students = await ApiClient.listStudents();

// Filter by grade (admin only)
final gradeStudents = await ApiClient.listStudents(grade: 'Grade 5');
```

### Get Student Details
```dart
final student = await ApiClient.getStudent('STU001');
// Student has: id, student_id, name, grade, parent_emails, created_at
```

### Create Student (Admin)
```dart
await ApiClient.createStudent(
  studentId: 'STU002',
  name: 'Jane Doe',
  grade: 'Grade 6',
  parentEmails: ['parent@example.com'],
);
```

## 📍 Attendance

### Record Face Event
```dart
await ApiClient.recordAttendance(
  studentId: 'STU001',
  studentName: 'John Doe',
  grade: 'Grade 5',
  status: 'Inside Campus',  // or 'Outside Campus'
  parentEmails: ['parent@example.com'],
);
```

### Get Student Attendance
```dart
final records = await ApiClient.getStudentAttendance('STU001', limit: 50);
// Each record has: id, student_id, student_name, grade, status, timestamp
```

### Get Parent Attendance (All Children)
```dart
final records = await ApiClient.getParentAttendance(limit: 100);
```

### Today's Attendance (Admin)
```dart
final records = await ApiClient.getTodayAttendance();
```

## 📊 Statistics (Admin Only)

### Database Stats
```dart
final stats = await ApiClient.getDatabaseStats();
// Returns: total_users, total_students, total_attendance_records
```

## 🛠️ Error Handling

```dart
try {
  final user = await ApiClient.getCurrentUser();
} on SocketException {
  print('No internet connection');
} on HttpException {
  print('HTTP error');
} on FormatException {
  print('Invalid response format');
} catch (e) {
  print('Error: $e');
}
```

## 🔄 Example: Full Login Flow

```dart
// 1. Login
try {
  final response = await ApiClient.login(email, password);
  final user = response['user'];
  
  if (user['user_type'] == 'admin') {
    Navigator.pushNamed(context, '/admin');
  } else {
    Navigator.pushNamed(context, '/parent');
  }
} catch (e) {
  showErrorDialog('Login failed: $e');
}

// 2. Fetch data after login
final students = await ApiClient.listStudents();
final attendance = await ApiClient.getParentAttendance();

// 3. Logout
ApiClient.logout();
```

## 🧪 Deployment Checklist

- [ ] Change default passwords
- [ ] Update SECRET_KEY
- [ ] Set ALLOWED_ORIGINS
- [ ] Use HTTPS
- [ ] Test with real device
- [ ] Enable error logging
- [ ] Configure CORS headers
- [ ] Set DEBUG=False
- [ ] Use production database URL

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Connection refused | Backend not running - run `run.bat` or `run.sh` |
| CORS error | Update ALLOWED_ORIGINS in backend/.env |
| 401 Unauthorized | Token expired - login again |
| 404 Not Found | Student/record doesn't exist |
| 403 Forbidden | Not authorized for this action |
| Database locked | Restart backend |

## 📞 Default Accounts

```
Email: admin@scmcies.com
Password: your_configured_admin_password
Role: Admin

Email: parent1@example.com
Password: your_configured_parent_password
Role: Parent

Email: parent2@example.com
Password: your_configured_parent_password
Role: Parent

Email: parent3@example.com
Password: your_configured_parent_password
Role: Parent
```

## 🌐 API Endpoints

```
GET    /health                           # Health check
GET    /docs                             # Swagger UI
POST   /auth/register                    # Register
POST   /auth/login                       # Login
GET    /auth/me                          # Current user
PUT    /auth/me                          # Update profile
GET    /students/                        # List students
GET    /students/{id}                    # Get student
POST   /attendance/                      # Record event
GET    /attendance/student/{id}          # Student history
GET    /attendance/parent/me             # Parent's children
GET    /stats/database/                  # Database stats
```

## 🔌 Environment Variables

```env
DEBUG=True                                # Debug mode
DATABASE_URL=sqlite:///./scmcies.db      # Database
SECRET_KEY=your-secret-key               # JWT secret
ACCESS_TOKEN_EXPIRE_MINUTES=30           # Token TTL
ALLOWED_ORIGINS=http://localhost:8000    # CORS origins
```

## 📖 Documentation

- API Docs: http://localhost:8000/docs
- Backend: [backend/README.md](backend/README.md)
- Integration: [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
- Database: [DATABASE_GUIDE.md](DATABASE_GUIDE.md)

## 💻 File Structure

```
SCMCIES APP/
├── backend/                 # FastAPI server
├── lib/
│   ├── services/api_client.dart
│   ├── models/
│   ├── pages/
│   └── main.dart
├── pubspec.yaml
└── INTEGRATION_GUIDE.md
```

## 🚨 Port Conflicts

If port 8000 is in use:
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :8000
kill -9 <PID>
```

## 🔐 Security Tips

- Never commit `.env` with real secrets
- Change default passwords immediately
- Use strong SECRET_KEY in production
- Enable HTTPS for API endpoints
- Restrict ALLOWED_ORIGINS
- Implement rate limiting
- Use environment variables for secrets
- Log security events

---

**Keep this reference handy! Bookmark for quick lookups.** 📌
