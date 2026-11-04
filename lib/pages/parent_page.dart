// ignore_for_file: use_build_context_synchronously

// Removed unused import 'dart:io'

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/face_recognition_service.dart';
import '../services/parent_account_service.dart';

class ParentPage extends StatefulWidget {
  final String? email;
  const ParentPage({super.key, this.email});

  @override
  State<ParentPage> createState() => _ParentPageState();
}

class _DrawerItemData {
  final IconData icon;
  final String label;
  final String key;

  const _DrawerItemData({required this.icon, required this.label, required this.key});
}

class _ParentPageState extends State<ParentPage> {
  // Parent account shown here (default changed as requested)
  String _parentName = 'Parent';
  String _parentEmail = 'archiegumbanbenoya08@gmail.com';

  // Password-change controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _adminNotificationsEnabled = true;
  String _selectedSection = 'students';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.email != null && widget.email!.isNotEmpty) {
      _parentEmail = widget.email!;
      _loadParentSettings(_parentEmail);
      return;
    }

    _loadLastLoggedInParent();
  }

  // Load persisted parent name from storage
  Future<void> _loadParentName(String email) async {
    final savedName = await ParentAccountService().getParentName(email);
    if (savedName != null && savedName.isNotEmpty) {
      if (mounted) {
        setState(() {
          _parentName = savedName;
        });
      }
    } else {
      // If no saved name, derive from email
      if (mounted) {
        setState(() {
          _parentName = _deriveNameFromEmail(email);
        });
      }
    }
  }

  Future<void> _loadLastLoggedInParent() async {
    final email = await ParentAccountService().getLastLoggedInEmail();
    if (email.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _parentEmail = email;
    });
    await _loadParentSettings(email);
  }

  Future<void> _loadParentSettings(String email) async {
    await Future.wait([
      _loadParentName(email),
      _loadNotificationPreferences(),
    ]);
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _adminNotificationsEnabled = prefs.getBool('parent_admin_notifications_enabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('parent_admin_notifications_enabled', _adminNotificationsEnabled);
  }

  Future<void> _promptParentChangeName() async {
    final controller = TextEditingController(text: _parentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ParentAccountService().saveParentName(_parentEmail, result);
      if (!mounted) return;
      setState(() {
        _parentName = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully')));
    }
  }

  Future<void> _promptParentChangeEmail() async {
    final controller = TextEditingController(text: _parentEmail);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Enter new email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    final newEmail = result?.trim();
    if (newEmail != null && newEmail.isNotEmpty && newEmail != _parentEmail) {
      await ParentAccountService().changeEmail(_parentEmail, newEmail, isAdmin: false);
      if (!mounted) return;
      setState(() {
        _parentEmail = newEmail;
      });
      await ParentAccountService().setLastLoggedInEmail(_parentEmail);
      _loadParentSettings(_parentEmail);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated successfully')));
    }
  }

  Future<void> _promptParentChangePassword() async {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Confirm password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      final currentPass = _currentPasswordController.text.trim();
      final newPass = _newPasswordController.text.trim();
      final confirm = _confirmPasswordController.text.trim();
      if (currentPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all password fields')));
        return;
      }
      if (newPass != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }

      final changed = await ParentAccountService().changePassword(
        _parentEmail,
        currentPassword: currentPass,
        newPassword: newPass,
      );
      if (!mounted) return;
      if (!changed) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current password is incorrect')));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
    }
  }

  Widget _buildParentDrawer() {
    final items = [
      _DrawerItemData(icon: Icons.dashboard, label: 'Dashboard', key: 'dashboard'),
      _DrawerItemData(icon: Icons.school, label: 'Students', key: 'students'),
      _DrawerItemData(icon: Icons.event, label: 'Events', key: 'events'),
      _DrawerItemData(icon: Icons.assessment, label: 'Reports', key: 'reports'),
      _DrawerItemData(icon: Icons.notifications, label: 'Notifications', key: 'notifications'),
      _DrawerItemData(icon: Icons.settings, label: 'Settings', key: 'settings'),
    ];

    return Drawer(
      child: Container(
        color: const Color(0xFF2A120A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: const Color(0xFF3A1C10),
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFE7B77A),
                    child: Icon(Icons.person, color: const Color(0xFF2A120A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PARENT PORTAL', style: TextStyle(color: Color(0xFFE7B77A), fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_parentName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((item) => ListTile(
                  leading: Icon(item.icon, color: _selectedSection == item.key ? const Color(0xFFE7B77A) : Colors.white70),
                  title: Text(item.label, style: TextStyle(color: _selectedSection == item.key ? const Color(0xFFE7B77A) : Colors.white, fontWeight: _selectedSection == item.key ? FontWeight.bold : FontWeight.w500)),
                  tileColor: _selectedSection == item.key ? const Color(0xFF3D2017) : null,
                  onTap: () {
                    setState(() => _selectedSection = item.key);
                    Navigator.pop(context);
                  },
                )),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final shouldLogout = await _confirmLogoutOnBack();
                if (shouldLogout && mounted) {
                  Navigator.pushReplacementNamed(context, '/welcome');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Student data is null until a face-recognition event is received
  Map<String, String>? _student;

  // Activity/card state
  String _lastEntryTime = '8:15 AM';
  String _lastExitTime = 'No exit yet';

  @override
  void initState() {
    super.initState();
    // listen for face-recognition events (service added)
    FaceRecognitionService.instance.register(_onFaceEvent);
    _seedExampleStudent();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    FaceRecognitionService.instance.unregister(_onFaceEvent);
    super.dispose();
  }

  void _seedExampleStudent() {
    if (_student != null) return;
    setState(() {
      _student = null;
      _lastEntryTime = 'No entry yet';
      _lastExitTime = 'No exit yet';
    });
  }

  // This function is exposed to update the parent UI when face-recognition occurs.
  // It will update student info, sidebox status, activity times and date.
  void handleFaceRecognitionEvent({
    required String studentId,
    required String studentName,
    required String grade,
    required String status, // 'Inside Campus' or 'Outside Campus'
    required DateTime timestamp,
    required List<String> parentEmails,
  }) {
    // only update this parent if the event is meant for them
    if (!parentEmails.contains(_parentEmail)) return;

    setState(() {
      _student = {
        'id': studentId,
        'name': studentName,
        'grade': grade,
        'status': status,
      };

      // update activity cards (simple example)
      final timeLabel = _formatTime(timestamp);
      if (status == 'Inside Campus') {
        _lastEntryTime = timeLabel;
      } else {
        _lastExitTime = timeLabel;
      }
    });

    // notify the shared service so Admin (and other listeners) can update
    FaceRecognitionService.instance.processEvent(FaceEvent(
      studentId: studentId,
      studentName: studentName,
      grade: grade,
      status: status,
      timestamp: timestamp,
      parentEmails: parentEmails,
    ));
  }

  // internal listener for global service events (keeps UI in sync)
  void _onFaceEvent(FaceEvent e) {
    // if this parent's email is included, mirror the same update
    if (e.parentEmails.contains(_parentEmail)) {
      handleFaceRecognitionEvent(
        studentId: e.studentId,
        studentName: e.studentName,
        grade: e.grade,
        status: e.status,
        timestamp: e.timestamp,
        parentEmails: e.parentEmails,
      );
    }
  }

  String _formatTime(DateTime dt) {
    // simple formatting HH:MM AM/PM
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _deriveNameFromEmail(String email) {
    final local = email.split('@').first;
    final parts = local.split(RegExp(r'[._]'));
    return parts.map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
  }

  Future<bool> _confirmLogoutOnBack() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    return result == true;
  }

  Widget _buildNotificationActionButton() {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: _showNotificationSheet,
      icon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/sfhsi.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _showNotificationSheet() {
    final notifications = [
      {'title': 'Campus Entry Confirmed', 'subtitle': 'Open the student activity view', 'destination': 'students', 'icon': Icons.school},
      {'title': 'Event Reminder', 'subtitle': 'Open the school events view', 'destination': 'events', 'icon': Icons.event},
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A120A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...notifications.map((item) => ListTile(
                  leading: Icon(item['icon'] as IconData, color: const Color(0xFFE7B77A)),
                  title: Text(item['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(item['subtitle'] as String, style: const TextStyle(color: Color(0xFFE8D7C8))),
                  onTap: () {
                    setState(() => _selectedSection = item['destination'] as String);
                    Navigator.pop(sheetContext);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_student == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3D2017),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB38157), width: 1.2),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, size: 36, color: Color(0xFFE7B77A)),
                  SizedBox(height: 12),
                  Text('No student activity yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('Student entry or exit updates will appear here as soon as they are recorded.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFE8D7C8))),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF3D2017),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB38157), width: 1.2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFB38157),
                    child: Text(
                      _student!['name']!.split(' ').map((p) => p[0]).take(2).join(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_student!['name']!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Grade ${_student!['grade'] ?? 'Grade -'}', style: const TextStyle(color: Color(0xFFE8D7C8), fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent.shade400, width: 1),
                    ),
                    child: Text(_student!['status'] == 'Inside Campus' ? 'On Campus' : 'Off Campus', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_student != null) ...[
            Row(
              children: [
                Expanded(child: _buildActivityCard(icon: Icons.login, title: 'Last Entry', time: _lastEntryTime, subtitle: 'Main Gate', borderColor: const Color(0xFFCC8D4A))),
                const SizedBox(width: 12),
                Expanded(child: _buildActivityCard(icon: Icons.logout, title: 'Last Exit', time: _lastExitTime, subtitle: 'Main Gate', borderColor: const Color(0xFFCC8D4A))),
              ],
            ),
            const SizedBox(height: 16),
            _buildActivityTimeline(),
          ],
        ],
      ),
    );
  }

  Widget _buildEventsSection() {
    final events = [
      {'title': 'Entered Campus', 'time': _lastEntryTime, 'location': 'Main Gate', 'color': const Color(0xFF5DBF7A)},
      {'title': 'Exited Campus', 'time': _lastExitTime, 'location': 'Main Gate', 'color': const Color(0xFFE09A58)},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('School Events', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Today\'s entry and exit activity', style: TextStyle(color: Color(0xFFE8D7C8))),
          const SizedBox(height: 18),
          ...events.map((event) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D2017),
                  border: Border(left: BorderSide(color: event['color'] as Color, width: 5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('${event['time']} • ${event['location']}', style: const TextStyle(color: Color(0xFFE8D7C8))),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: event['color'] as Color, size: 18),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildReportsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Report', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Campus attendance summary', style: TextStyle(color: Color(0xFFE8D7C8))),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _buildReportMetric('Entries', _student == null ? '0' : '1', const Color(0xFF5DBF7A))),
              const SizedBox(width: 12),
              Expanded(child: _buildReportMetric('Exits', _student == null ? '0' : '0', const Color(0xFFE09A58))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2017),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB38157), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    final notifications = [
      {'title': 'Campus Entry Confirmed', 'subtitle': 'Sofia Reyes entered campus via Main Gate', 'time': '07:42 AM', 'destination': 'students'},
      {'title': 'Event Reminder', 'subtitle': 'Parent-Teacher Conference today at 2:00 PM in AVR', 'time': '07:00 AM', 'destination': 'events'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Campus alerts for your child', style: TextStyle(color: Color(0xFFE8D7C8))),
          const SizedBox(height: 16),
          ...notifications.map((n) => InkWell(
                onTap: () => setState(() => _selectedSection = n['destination'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D2017),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFB38157), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: const Color(0xFFE7B77A), borderRadius: BorderRadius.circular(18)),
                        child: Image.asset('assets/sfhsi.png', width: 20, height: 20, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(n['subtitle'] as String, style: const TextStyle(color: Color(0xFFE8D7C8))),
                          ],
                        ),
                      ),
                      Text(n['time'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Account preferences and notifications', style: TextStyle(color: Color(0xFFE8D7C8))),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2017),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB38157), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFFE7B77A)),
                  title: Text(_parentName, style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.edit, color: Color(0xFFE7B77A)),
                  onTap: _promptParentChangeName,
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Color(0xFFE7B77A)),
                  title: Text(_parentEmail, style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.edit, color: Color(0xFFE7B77A)),
                  onTap: _promptParentChangeEmail,
                ),
                ListTile(
                  leading: const Icon(Icons.lock, color: Color(0xFFE7B77A)),
                  title: const Text('Change password', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward, color: Color(0xFFE7B77A)),
                  onTap: _promptParentChangePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2017),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB38157), width: 1.2),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _adminNotificationsEnabled,
                  onChanged: (v) async {
                    setState(() => _adminNotificationsEnabled = v);
                    await _saveNotificationPreferences();
                  },
                  title: const Text('Push notifications', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Receive app updates and activity alerts', style: TextStyle(color: Color(0xFFE8D7C8))),
                  activeThumbColor: const Color(0xFFE7B77A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentMainBody() {
    switch (_selectedSection) {
      case 'dashboard':
        return _buildStudentSection();
      case 'students':
        return _buildStudentSection();
      case 'events':
        return _buildEventsSection();
      case 'reports':
        return _buildReportsSection();
      case 'notifications':
        return _buildNotificationsSection();
      case 'settings':
        return _buildSettingsSection();
      default:
        return _buildStudentSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLogout = await _confirmLogoutOnBack();
        if (shouldLogout && mounted) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2A120A),
        drawer: _buildParentDrawer(),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3A1C10),
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text('SFHSI Parent Dashboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          actions: [_buildNotificationActionButton()],
        ),
        body: _buildParentMainBody(),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String time,
    required String subtitle,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[100]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: Colors.brown[700]!, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[100]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.trending_up, color: Colors.brown[700], size: 24),
          const SizedBox(height: 12),
          Text(
            'Today',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '1 events',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1 entries, 0 exits',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3D2017),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB38157), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_today, color: Color(0xFFE7B77A), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Activity Timeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE8D7C8),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildTimelineEvent(
                  icon: Icons.login,
                  title: 'Entered Campus',
                  time: _lastEntryTime,
                  date: dateStr,
                  location: 'Main Gate',
                  isFirst: true,
                ),
                const SizedBox(height: 14),
                _buildTimelineEvent(
                  icon: Icons.logout,
                  title: 'Exited Campus',
                  time: _lastExitTime,
                  date: dateStr,
                  location: 'Main Gate',
                  isFirst: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent({
    required IconData icon,
    required String title,
    required String time,
    required String date,
    required String location,
    required bool isFirst,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.brown[100],
              ),
              child: Icon(icon, color: Colors.brown[700], size: 20),
            ),
            if (!isFirst)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '$time • $date',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

}

