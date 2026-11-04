# SCMCIES Full Stack Setup - FastAPI Backend + Flutter Frontend

This document explains how to set up and run both the FastAPI backend and Flutter frontend together.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App (Mobile/Web)                │
│                      (lib/ directory)                           │
└─────────────┬───────────────────────────────────────────────────┘
              │
              │ HTTP Requests (REST API)
              │ JSON over HTTP/HTTPS
              │
┌─────────────▼───────────────────────────────────────────────────┐
│                    FastAPI Backend Server                        │
│                    (backend/ directory)                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Routes: /auth, /users, /students, /attendance, /stats    │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Database: SQLite (scmcies.db)                            │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
SCMCIES APP/
├── lib/
│   ├── main.dart                    # Flutter app entry point
│   ├── models/                      # Data models
│   ├── services/
│   │   ├── api_client.dart         # NEW: HTTP client for backend
│   │   ├── app_database_service.dart
│   │   ├── parent_account_service.dart
│   │   └── face_recognition_service.dart
│   ├── pages/                      # UI pages
│   └── ...
├── backend/                         # NEW: FastAPI backend
│   ├── app/
│   │   ├── models/                 # SQLAlchemy models
│   │   ├── schemas/                # Pydantic schemas
│   │   ├── routes/                 # API endpoints
│   │   └── core/                   # Config, DB, security
│   ├── main.py                     # FastAPI app
│   ├── requirements.txt            # Python dependencies
│   ├── .env.example                # Environment config template
│   ├── run.bat                     # Windows startup script
│   ├── run.sh                      # Linux/Mac startup script
│   └── README.md                   # Backend documentation
├── pubspec.yaml                    # Flutter dependencies
├── DATABASE_GUIDE.md               # SQLite database guide
├── SETUP_SUMMARY.md               # Initial setup summary
└── INTEGRATION_GUIDE.md            # This file
```

## Setup Instructions

### Step 1: Start the FastAPI Backend

#### On Windows:
```cmd
cd backend
run.bat
```

#### On Linux/Mac:
```bash
cd backend
chmod +x run.sh
./run.sh
```

#### Expected Output:
```
🚀 SCMCIES FastAPI Backend
================================
✅ Python found: Python 3.11.0
🔌 Activating virtual environment...
📥 Installing dependencies...
🎉 Starting FastAPI Server...
📍 API URL: http://localhost:8000
📖 Documentation: http://localhost:8000/docs

INFO:     Uvicorn running on http://0.0.0.0:8000
✅ Default users created successfully
```

### Step 2: Verify Backend is Running

Open in browser:
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **API Root**: http://localhost:8000/

### Step 3: Update Flutter App Configuration

Update the API base URL in [lib/services/api_client.dart](lib/services/api_client.dart):

```dart
// For local development:
static const String baseUrl = 'http://localhost:8000';

// For Android emulator:
// static const String baseUrl = 'http://10.0.2.2:8000';

// For production:
// static const String baseUrl = 'https://api.scmcies.com';
```

### Step 4: Run Flutter App

```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Or run web version
flutter run -d chrome
```

## API Endpoints Overview

### Authentication
```
POST   /auth/register          - Register new account
POST   /auth/login             - Login and get JWT token
GET    /auth/me                - Get current user
PUT    /auth/me                - Update profile
DELETE /auth/me                - Delete account
```

### Users (Admin only)
```
GET    /users/                 - List all users
GET    /users/{id}             - Get specific user
POST   /users/                 - Create user
PUT    /users/{id}             - Update user
DELETE /users/{id}             - Delete user
```

### Students
```
GET    /students/              - List students
GET    /students/{id}          - Get student
POST   /students/              - Register student (Admin)
PUT    /students/{id}          - Update student (Admin)
DELETE /students/{id}          - Delete student (Admin)
```

### Attendance
```
GET    /attendance/            - List all (Admin)
POST   /attendance/            - Record event
GET    /attendance/student/{id} - Student records
GET    /attendance/parent/me   - Parent's children
GET    /attendance/today/      - Today's records (Admin)
```

### Statistics (Admin only)
```
GET    /stats/database/        - DB stats
GET    /stats/grades/          - Students by grade
GET    /stats/attendance/today/ - Today's attendance
```

## Using the API Client in Flutter

### 1. Login

```dart
import 'package:example/services/api_client.dart';

void loginExample() async {
  try {
    final response = await ApiClient.login(
      'parent1@example.com',
      'your_configured_parent_password',
    );
    print('Login successful!');
    print('Token: ${ApiClient.authToken}');
    print('User: ${response['user']}');
  } catch (e) {
    print('Login failed: $e');
  }
}
```

### 2. Get Current User

```dart
void getCurrentUserExample() async {
  try {
    final user = await ApiClient.getCurrentUser();
    print('User: ${user.name}, Email: ${user.email}');
  } catch (e) {
    print('Error: $e');
  }
}
```

### 3. List Students (Parent View)

```dart
void getStudentsExample() async {
  try {
    final students = await ApiClient.listStudents();
    for (var student in students) {
      print('Student: ${student.name}, Grade: ${student.grade}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### 4. Get Attendance

```dart
void getAttendanceExample() async {
  try {
    // For parent - their children's attendance
    final attendance = await ApiClient.getParentAttendance(limit: 50);
    for (var record in attendance) {
      print('${record.studentName}: ${record.status} at ${record.timestamp}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### 5. Record Face Recognition Event

```dart
void recordAttendanceExample() async {
  try {
    final record = await ApiClient.recordAttendance(
      studentId: 'STU001',
      studentName: 'John Doe',
      grade: 'Grade 5',
      status: 'Inside Campus',
      parentEmails: ['parent1@example.com'],
    );
    print('Attendance recorded at: ${record.timestamp}');
  } catch (e) {
    print('Error: $e');
  }
}
```

### 6. Get Admin Statistics

```dart
void getStatsExample() async {
  try {
    final stats = await ApiClient.getDatabaseStats();
    print('Total users: ${stats['total_users']}');
    print('Total students: ${stats['total_students']}');
    print('Total attendance: ${stats['total_attendance_records']}');
  } catch (e) {
    print('Error: $e');
  }
}
```

## Updating Pages to Use Backend API

### Example: Login Page

Before (using local database):
```dart
final verified = await _accountService.verifyCredentials(email, password);
```

After (using API):
```dart
try {
  final response = await ApiClient.login(email, password);
  // Login successful, ApiClient.authToken is set automatically
  Navigator.pushNamed(context, '/parent');
} on Exception catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Login failed: $e')),
  );
}
```

### Example: Parent Page - Show Children Attendance

```dart
import 'package:example/services/api_client.dart';
import 'package:example/models/attendance_model.dart';

class ParentPage extends StatefulWidget {
  @override
  State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  late Future<List<AttendanceRecord>> attendanceFuture;

  @override
  void initState() {
    super.initState();
    // Fetch attendance from backend API
    attendanceFuture = ApiClient.getParentAttendance(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Children Attendance')),
      body: FutureBuilder<List<AttendanceRecord>>(
        future: attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final records = snapshot.data ?? [];
          
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return ListTile(
                title: Text(record.studentName),
                subtitle: Text('${record.status} - ${record.timestamp}'),
                trailing: Icon(
                  record.status == 'Inside Campus'
                    ? Icons.check_circle
                    : Icons.exit_to_app,
                  color: record.status == 'Inside Campus'
                    ? Colors.green
                    : Colors.red,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### Example: Admin Page - View Statistics

```dart
class AdminPage extends StatefulWidget {
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<Map<String, dynamic>> statsFuture;

  @override
  void initState() {
    super.initState();
    statsFuture = ApiClient.getDatabaseStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final stats = snapshot.data ?? {};
          
          return Column(
            children: [
              Card(
                child: ListTile(
                  title: const Text('Total Users'),
                  trailing: Text('${stats['total_users']}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Total Students'),
                  trailing: Text('${stats['total_students']}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Total Attendance Records'),
                  trailing: Text('${stats['total_attendance_records']}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

## Database Synchronization

### Option 1: API-Only (Recommended)
- Flutter app sends all requests to FastAPI backend
- API returns data from backend SQLite database
- Local database [lib database] is not used
- Setup: All changes go through API endpoints

### Option 2: Hybrid (API + Local Caching)
- Flutter app uses local database for offline caching
- Syncs with API when online
- Useful for offline-first applications

### Option 3: Local-Only (No Backend)
- Flutter app uses only local SQLite database
- Good for development/testing
- No API calls needed

## Environment Configuration

### Development

**.env in backend/**
```env
DEBUG=True
DATABASE_URL=sqlite:///./scmcies.db
SECRET_KEY=dev-secret-key
ALLOWED_ORIGINS=http://localhost:8000,http://localhost:3000
```

**api_client.dart**
```dart
static const String baseUrl = 'http://localhost:8000';
// For Android emulator:
// static const String baseUrl = 'http://10.0.2.2:8000';
```

### Production

**.env in backend/**
```env
DEBUG=False
DATABASE_URL=postgresql://user:pass@prod-db.com/scmcies
SECRET_KEY=generate-strong-secret-key
ALLOWED_ORIGINS=https://app.scmcies.com
```

**api_client.dart**
```dart
static const String baseUrl = 'https://api.scmcies.com';
```

## Testing

### Test Backend API

```bash
# Using curl
curl -X GET http://localhost:8000/health

# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@scmcies.com","password":"your_configured_admin_password"}'
```

### Test Flutter with Backend

```bash
# Run with verbose logging
flutter run -v

# Check network requests - look for http calls in logs
```

## Troubleshooting

### Backend won't start
```bash
# Check Python version
python --version

# Install dependencies
pip install -r requirements.txt

# Try running directly
python -m uvicorn main:app --reload
```

### CORS errors in Flutter
- Update `ALLOWED_ORIGINS` in backend `.env`
- Ensure Flutter app is accessing correct API URL
- Check browser console for detailed error

### Can't connect to API
```dart
// Check if backend is running
// Test with:
final response = await ApiClient.getDatabaseStats();
```

### Database locked error
- Restart the backend server
- Delete `scmcies.db` if needed

### Token expired
- Re-login to get new token
- Refresh token endpoint coming soon

## Production Deployment

### Deploy Backend

Using Heroku:
```bash
cd backend
heroku create scmcies-api
git push heroku main
```

Using Docker:
```bash
docker build -t scmcies-api backend/
docker run -p 8000:8000 scmcies-api
```

### Deploy Flutter App

Build APK:
```bash
flutter build apk --release
```

Build iOS:
```bash
flutter build ios --release
```

Build Web:
```bash
flutter build web --release
```

## Next Steps

1. ✅ Start backend: `run.bat` or `run.sh`
2. ✅ Verify API docs at http://localhost:8000/docs
3. ✅ Update Flutter API endpoint in [lib/services/api_client.dart]
4. ✅ Run `flutter pub get` to install http package
5. ✅ Update your pages to use `ApiClient` instead of local services
6. ✅ Test login with configured credentials
7. ✅ Build and deploy!

## Architecture Decisions

| Component | Technology | Why |
|-----------|-----------|-----|
| Frontend | Flutter | Cross-platform (iOS, Android, Web) |
| Backend | FastAPI | Fast, easy to learn, Python ecosystem |
| Database | SQLite | Simple, zero-config for development |
| ORM | SQLAlchemy | Flexible, powerful Python ORM |
| Auth | JWT | Stateless, scalable token-based auth |

## API Documentation

Auto-generated API docs available at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

These are interactive and allow testing endpoints directly from the browser.

## Performance Tips

1. Implement pagination for large datasets
2. Add caching headers to reduce API calls
3. Use database indices on frequently queried columns
4. Batch API requests when possible
5. Implement offline support with local caching

## Security Checklist

- [ ] Change default user passwords
- [ ] Update `SECRET_KEY` to strong random value
- [ ] Use HTTPS in production
- [ ] Restrict `ALLOWED_ORIGINS`
- [ ] Implement rate limiting
- [ ] Add request logging and monitoring
- [ ] Use environment variables for secrets
- [ ] Regular security audits

---

**Full Stack is ready! Start backend, then run Flutter app.** 🚀
