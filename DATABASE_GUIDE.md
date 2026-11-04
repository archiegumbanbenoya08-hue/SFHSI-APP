# SCMCIES Database Documentation

This document explains how to use the SQLite database in the SCMCIES application.

## Overview

The database stores:
- **Users**: Admin and parent accounts with credentials
- **Students**: Student records with grades and associated parents
- **Attendance Records**: Face recognition events (entry/exit campus)

## Database Files

- `lib/database/database_helper.dart` - Main database interface
- `lib/models/user_model.dart` - User data model
- `lib/models/student_model.dart` - Student data model
- `lib/models/attendance_model.dart` - Attendance record model

## Usage Examples

### 1. Working with Users

```dart
import 'package:example/database/database_helper.dart';
import 'package:example/models/user_model.dart';

final db = DatabaseHelper();

// Get a user by email
final user = await db.getUserByEmail('parent1@example.com');
print('User: ${user?.name}');

// Update password
await db.updateUserPassword('parent1@example.com', 'newPassword123');

// Update name
await db.updateUserName('parent1@example.com', 'New Name');

// Get all users
final allUsers = await db.getAllUsers();

// Get all parent users
final parents = await db.getAllParents();
```

### 2. Working with Students

```dart
// Add a new student
final newStudent = Student(
  studentId: 'STU001',
  name: 'John Doe',
  grade: 'Grade 5',
  parentEmails: ['parent1@example.com'],
  createdAt: DateTime.now(),
);
final studentId = await db.addStudent(newStudent);

// Get student by ID
final student = await db.getStudentById('STU001');

// Get students by grade
final gradeStudents = await db.getStudentsByGrade('Grade 5');

// Get students by parent email
final parentStudents = await db.getStudentsByParentEmail('parent1@example.com');

// Update student
final updatedStudent = student!.copyWith(
  name: 'Jane Doe',
  parentEmails: ['parent1@example.com', 'parent2@example.com'],
);
await db.updateStudent(updatedStudent);

// Delete student
await db.deleteStudent('STU001');

// Get all students
final allStudents = await db.getAllStudents();
```

### 3. Working with Attendance Records

```dart
import 'package:example/models/attendance_model.dart';

// Add an attendance record (triggered by face recognition)
final attendance = AttendanceRecord(
  studentId: 'STU001',
  studentName: 'John Doe',
  grade: 'Grade 5',
  status: 'Inside Campus',
  timestamp: DateTime.now(),
  parentEmails: ['parent1@example.com'],
);
await db.addAttendanceRecord(attendance);

// Get all attendance records
final allRecords = await db.getAllAttendanceRecords();

// Get attendance records for a specific student
final studentRecords = await db.getAttendanceRecordsByStudent('STU001');

// Get attendance records for a date range
final records = await db.getAttendanceRecordsByDateRange(
  DateTime(2024, 3, 1),
  DateTime(2024, 3, 31),
);

// Get records for a parent
final parentRecords = await db.getAttendanceRecordsForParent('parent1@example.com');

// Delete old records (older than 90 days)
await db.deleteOldAttendanceRecords(90);
```

### 4. Using with Face Recognition Service

The `FaceRecognitionService` can save events to database:

```dart
import 'package:example/services/face_recognition_service.dart';

// When face is detected, save to database
void saveFaceEvent(FaceEvent event) async {
  final db = DatabaseHelper();
  final record = AttendanceRecord(
    studentId: event.studentId,
    studentName: event.studentName,
    grade: event.grade,
    status: event.status,
    timestamp: event.timestamp,
    parentEmails: event.parentEmails,
  );
  await db.addAttendanceRecord(record);
}
```

### 5. Database Maintenance

```dart
// Get database statistics
final stats = await db.getDatabaseStats();
print('Users: ${stats['users']}');
print('Students: ${stats['students']}');
print('Attendance: ${stats['attendance']}');

// Clear all data (use with caution!)
await db.clearDatabase();

// Close database
await db.closeDatabase();
```

## Default Users

The database is pre-populated with these accounts:

| Email | Password | Name | Type |
|-------|----------|------|------|
| parent1@example.com | your_configured_parent_password | Parent One | parent |
| parent2@example.com | your_configured_parent_password | Parent Two | parent |
| parent3@example.com | your_configured_parent_password | Parent Three | parent |
| admin@scmcies.com | your_configured_admin_password | Administrator | admin |

## Database Location

The SQLite database file is stored at:
- **Android**: `/data/data/com.example.app/databases/scmcies.db`
- **iOS**: `Documents/scmcies.db`
- **Other platforms**: Platform-specific documents directory

## Integration with Pages

### Login Page
- Use `ParentAccountService.verifyCredentials()` to authenticate
- Data is now retrieved from database instead of SharedPreferences

### Admin Page
- Query all students: `db.getAllStudents()`
- Query attendance records: `db.getAllAttendanceRecords()`
- Get statistics: `db.getDatabaseStats()`

### Parent Page
- Get student records: `db.getStudentsByParentEmail(parentEmail)`
- Get attendance: `db.getAttendanceRecordsForParent(parentEmail)`

## Best Practices

1. **Always handle exceptions** when performing database operations
2. **Use limiting** when querying large datasets to improve performance
3. **Close the database** when app terminates (not critical but recommended)
4. **Delete old records regularly** to keep database size manageable
5. **Batch operations** when inserting multiple records

## Example Integration in LoginPage

```dart
import 'package:example/services/parent_account_service.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _accountService = ParentAccountService();

  void _handleLogin() async {
    final credentials = await _accountService.verifyCredentials(
      _emailController.text,
      _passwordController.text,
    );
    
    if (credentials) {
      // Login successful
      Navigator.of(context).pushNamed('/parent');
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Column(
        children: [
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password')),
          ElevatedButton(onPressed: _handleLogin, child: const Text('Login')),
        ],
      ),
    );
  }
}
```

## Troubleshooting

- **Database not found**: Ensure `sqflite` and `path` packages are installed
- **Can't query data**: Check that database has been initialized by calling a method first
- **Performance slow**: Delete old records and consider adding indices for frequently queried columns
- **Migration errors**: The database is created fresh on first app install

For more information, refer to the [sqflite documentation](https://github.com/tekartik/sqflite).
