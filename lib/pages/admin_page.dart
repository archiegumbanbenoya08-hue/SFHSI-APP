import 'package:flutter/material.dart';

import '../services/app_connection_service.dart';
import '../services/backend_api_service.dart';
import '../services/message_service.dart';
import '../services/parent_account_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

enum LogStatus { all, entry, exit }

extension LogStatusExtension on LogStatus {
  String get label {
    switch (this) {
      case LogStatus.entry:
        return 'Entry';
      case LogStatus.exit:
        return 'Exit';
      default:
        return 'All Status';
    }
  }

  bool matches(String status) {
    if (this == LogStatus.all) return true;
    if (this == LogStatus.entry) return status == 'Inside Campus';
    return status == 'Outside Campus';
  }
}

class AdminStudent {
  final String id;
  final String name;
  final String section;
  final String grade;
  final String parent;
  final String parentEmail;
  final String status;
  final String imageUrl;
  final String lastSeen;

  AdminStudent({
    required this.id,
    required this.name,
    required this.section,
    required this.grade,
    required this.parent,
    required this.parentEmail,
    required this.status,
    required this.imageUrl,
    required this.lastSeen,
  });

  factory AdminStudent.fromJson(Map<String, dynamic> json) {
    final databaseStatus = '${json['status'] ?? ''}';
    return AdminStudent(
      id: '${json['student_id'] ?? json['id'] ?? ''}',
      name: '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      section: '${json['section'] ?? 'N/A'}',
      grade: '${json['grade_level'] ?? 'N/A'}',
      parent: '${json['parent_name'] ?? 'Parent'}',
      parentEmail: '${json['parent_email'] ?? ''}',
      status: databaseStatus == 'IN_CAMPUS'
          ? 'Inside Campus'
          : databaseStatus == 'NOT_IN_CAMPUS'
          ? 'Outside Campus'
          : databaseStatus,
      imageUrl: '',
      lastSeen: '${json['last_seen'] ?? ''}',
    );
  }
}

class _AdminPageState extends State<AdminPage> {
  String _searchQuery = '';
  String _selectedGrade = 'All Grades';
  final List<String> _grades = [
    'All Grades',
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
  ];
  LogStatus _selectedLogStatus = LogStatus.all;

  String _adminName = 'Administrator';
  String _adminEmail = '';
  String _selectedSection = 'students';
  String _selectedParentEmail = '';
  List<String> _parentEmails = [];
  bool _parentsCollapsed = false;
  final TextEditingController _adminMessageController = TextEditingController();

  final List<AdminStudent> _students = [];

  @override
  void initState() {
    super.initState();
    _loadAdminSettings();
  }

  @override
  void dispose() {
    _adminMessageController.dispose();
    super.dispose();
  }

  List<AdminStudent> get _filteredStudents {
    return _students.where((student) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGrade =
          _selectedGrade == 'All Grades' || student.grade == _selectedGrade;
      final matchesLogStatus = _selectedLogStatus.matches(student.status);
      return matchesSearch && matchesGrade && matchesLogStatus;
    }).toList();
  }

  int get _totalStudents => _filteredStudents.length;

  int get _currentlyInside => _filteredStudents
      .where((student) => student.status == 'Inside Campus')
      .length;

  int get _totalEntries =>
      _students.where((student) => student.status == 'Inside Campus').length;

  int get _totalExits =>
      _students.where((student) => student.status == 'Outside Campus').length;

  Future<void> _loadAdminSettings() async {
    try {
      final api = BackendApiService.instance;
      final profile = await api.getProfile();
      final parents = await api.getParents();
      final students = await api.getStudents();
      if (!mounted) return;

      setState(() {
        _adminEmail = profile.email;
        _adminName = profile.name;
        _parentEmails = parents
            .map((parent) => '${parent['email'] ?? ''}')
            .where((email) => email.isNotEmpty)
            .toList();
        if (!_parentEmails.contains(_selectedParentEmail)) {
          _selectedParentEmail = _parentEmails.isEmpty ? '' : _parentEmails.first;
        }
        _students
          ..clear()
          ..addAll(students.map(AdminStudent.fromJson));
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load database records: $error')),
        );
      }
    }
  }

  Future<void> _promptAdminChangeName() async {
    final controller = TextEditingController(text: _adminName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      await ParentAccountService().saveParentName(_adminEmail, result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update name: $error')),
      );
      return;
    }
    if (!mounted) return;

    setState(() {
      _adminName = result;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin name updated successfully')),
    );
  }

  Future<void> _promptAdminChangeEmail() async {
    final controller = TextEditingController(text: _adminEmail);
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final newEmail = result?.trim();
    if (newEmail == null || newEmail.isEmpty || newEmail == _adminEmail) return;

    try {
      await ParentAccountService().changeEmail(
        _adminEmail,
        newEmail,
        isAdmin: true,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update email: $error')),
      );
      return;
    }
    if (!mounted) return;

    setState(() {
      _adminEmail = newEmail;
    });
    await ParentAccountService().setLastLoggedInEmail(_adminEmail);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin email updated successfully')),
    );
  }

  Future<void> _promptAdminChangePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Confirm password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all password fields')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final changed = await ParentAccountService().changePassword(
      _adminEmail,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (!mounted) return;

    if (!changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current password is incorrect')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin password updated successfully')),
    );
  }

  Widget _buildAdminDrawer() {
    final items = [
      {'icon': Icons.dashboard, 'title': 'Dashboard', 'key': 'dashboard'},
      {'icon': Icons.people, 'title': 'Students', 'key': 'students'},
      {'icon': Icons.event, 'title': 'Events', 'key': 'events'},
      {'icon': Icons.assessment, 'title': 'Reports', 'key': 'reports'},
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'key': 'notifications',
      },
      {'icon': Icons.settings, 'title': 'Settings', 'key': 'settings'},
    ];

    return Drawer(
      backgroundColor: const Color(0xFF3A1C10),
      child: Container(
        color: const Color(0xFF3A1C10),
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
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Color(0xFF2A120A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ADMIN PORTAL',
                          style: TextStyle(
                            color: Color(0xFFE7B77A),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _adminName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...items.map(
              (item) => ListTile(
                leading: Icon(
                  item['icon'] as IconData,
                  color: _selectedSection == item['key']
                      ? const Color(0xFFE7B77A)
                      : Colors.white70,
                ),
                title: Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: _selectedSection == item['key']
                        ? const Color(0xFFE7B77A)
                        : Colors.white,
                    fontWeight: _selectedSection == item['key']
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
                tileColor: _selectedSection == item['key']
                    ? const Color(0xFF3D2017)
                    : null,
                onTap: () {
                  setState(() => _selectedSection = item['key'] as String);
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(color: Colors.white24),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                final should = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Do you want to logout your account?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (should == true && mounted) {
                  ParentAccountService().logout();
                  Navigator.pushReplacementNamed(context, '/welcome');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildNotificationActionButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
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
      {
        'title': 'New parent message',
        'subtitle': 'Open the message thread',
        'destination': 'messages',
        'icon': Icons.message,
      },
      {
        'title': 'Campus update',
        'subtitle': 'Review recent activity',
        'destination': 'notifications',
        'icon': Icons.notifications,
      },
      {
        'title': 'Account settings',
        'subtitle': 'Update your admin profile',
        'destination': 'settings',
        'icon': Icons.settings,
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A120A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...notifications.map(
              (item) => ListTile(
                leading: Icon(
                  item['icon'] as IconData,
                  color: const Color(0xFFE7B77A),
                ),
                title: Text(
                  item['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  item['subtitle'] as String,
                  style: const TextStyle(color: Color(0xFFE8D7C8)),
                ),
                onTap: () {
                  setState(
                    () => _selectedSection = item['destination'] as String,
                  );
                  Navigator.pop(sheetContext);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMessageSection() {
    final parentEmails = _parentEmails;
    if (parentEmails.isEmpty) {
      return const Center(
        child: Text(
          'No parent accounts found in the database.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return Container(
      color: const Color(0xFF2A120A),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: _parentsCollapsed ? 56 : 240,
            decoration: BoxDecoration(
              color: const Color(0xFF2A120A),
              border: Border(
                right: BorderSide(color: const Color(0xFFB38157), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_parentsCollapsed)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text(
                            'Messages',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          _parentsCollapsed
                              ? Icons.arrow_forward_ios
                              : Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => setState(
                          () => _parentsCollapsed = !_parentsCollapsed,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                if (_parentsCollapsed)
                  // Collapsed: show compact scrollable avatars so admin can scroll profiles
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: parentEmails.length,
                      itemBuilder: (context, idx) {
                        final email = parentEmails[idx];
                        final displayName = email
                            .split('@')
                            .first
                            .replaceAll(RegExp(r'[0-9]'), '');
                        final initials = displayName
                            .split('')
                            .take(2)
                            .join()
                            .toUpperCase();
                        final selected = _selectedParentEmail == email;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedParentEmail = email),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: selected
                                  ? const Color(0xFFE7B77A)
                                  : const Color(0xFFB38157),
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFF2A120A)
                                      : const Color(0xFF2A120A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: parentEmails.length,
                      itemBuilder: (context, index) {
                        final email = parentEmails[index];
                        return FutureBuilder<List<ChatMessage>>(
                          future: MessageService().getConversation(
                            _adminEmail,
                            email,
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox.shrink();
                            final messages = snapshot.data ?? [];
                            final lastMessage = messages.isNotEmpty
                                ? messages.last
                                : null;
                            final displayName = email
                                .split('@')
                                .first
                                .replaceAll(RegExp(r'[0-9]'), '');
                            final initials = displayName
                                .split('')
                                .take(2)
                                .join()
                                .toUpperCase();

                            return ListTile(
                              onTap: () =>
                                  setState(() => _selectedParentEmail = email),
                              selected: _selectedParentEmail == email,
                              selectedTileColor: const Color(0xFF3D2017),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFB38157),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Color(0xFF2A120A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                lastMessage != null &&
                                        lastMessage.text.length > 30
                                    ? '${lastMessage.text.substring(0, 30)}...'
                                    : lastMessage?.text ?? 'No messages',
                                style: const TextStyle(
                                  color: Color(0xFFE8D7C8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: messages.isNotEmpty
                                  ? Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE7B77A),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        messages.length.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF2A120A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ChatMessage>>(
              future: MessageService().getConversation(
                _adminEmail,
                _selectedParentEmail,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load messages: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }
                final messages = snapshot.data ?? const <ChatMessage>[];
                final displayName = _selectedParentEmail.split('@').first;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A1C10),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFFB38157),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFB38157),
                            child: Text(
                              displayName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF2A120A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Color(0xFFE7B77A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: messages.isEmpty
                          ? Center(
                              child: Text(
                                'No messages yet',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isFromAdmin =
                                    message.sender.toLowerCase() ==
                                    _adminEmail.toLowerCase();
                                return Align(
                                  alignment: isFromAdmin
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    constraints: const BoxConstraints(
                                      maxWidth: 300,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFromAdmin
                                          ? const Color(0xFFE7B77A)
                                          : const Color(0xFF3D2017),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isFromAdmin
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.text,
                                          style: TextStyle(
                                            color: isFromAdmin
                                                ? const Color(0xFF2A120A)
                                                : Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')} ${message.createdAt.hour >= 12 ? 'PM' : 'AM'}',
                                          style: TextStyle(
                                            color: isFromAdmin
                                                ? const Color(
                                                    0xFF2A120A,
                                                  ).withValues(alpha: 0.7)
                                                : Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: const Color(0xFFB38157),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _adminMessageController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFE8D7C8),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF3D2017),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFB38157),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final text = _adminMessageController.text.trim();
                              if (text.isEmpty) return;

                              final isConnected = await AppConnectionService()
                                  .canUseApp();
                              if (!isConnected) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Live messaging requires an internet connection.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                await MessageService().saveMessage(
                                  sender: _adminEmail,
                                  receiver: _selectedParentEmail,
                                  text: text,
                                  isAdmin: true,
                                );
                                _adminMessageController.clear();
                                if (mounted) setState(() {});
                              } catch (error) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not send message: $error'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE7B77A),
                              foregroundColor: const Color(0xFF2A120A),
                            ),
                            child: const Text('Send'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMainBody() {
    switch (_selectedSection) {
      case 'dashboard':
      case 'students':
        return SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.people,
                        title: _totalStudents.toString(),
                        subtitle: 'Total Students',
                        color: const Color(0xFFB38157),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.apartment,
                        title: _currentlyInside.toString(),
                        subtitle: 'Currently Inside',
                        color: const Color(0xFFB38157),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.login,
                        title: _totalEntries.toString(),
                        subtitle: 'Total Entries',
                        color: const Color(0xFFB38157),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.logout,
                        title: _totalExits.toString(),
                        subtitle: 'Total Exits',
                        color: const Color(0xFFB38157),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildStudentFilterSection(),
              const SizedBox(height: 24),
              _buildSearchAndStatusSection(),
              const SizedBox(height: 16),
              _students.isEmpty ? _buildNoStudentState() : _buildStudentTable(),
              const SizedBox(height: 24),
            ],
          ),
        );
      case 'events':
        final recentEvents = [..._students]
          ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF68432D), Color(0xFF3D2017)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFB38157)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.history, color: Color(0xFFE7B77A), size: 32),
                        SizedBox(height: 14),
                        Text(
                          'Campus Events',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Recent student entry and exit activity',
                          style: TextStyle(color: Color(0xFFE8D7C8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildEventSummaryCard(
                        icon: Icons.login,
                        label: 'Currently on campus',
                        value: _currentlyInside.toString(),
                        accent: const Color(0xFF8FC99A),
                      ),
                      _buildEventSummaryCard(
                        icon: Icons.door_front_door_outlined,
                        label: 'Outside campus',
                        value: (_students.length - _currentlyInside).toString(),
                        accent: const Color(0xFFE7B77A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (recentEvents.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D2017),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF68432D)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.event_note,
                            color: Color(0xFFE7B77A),
                            size: 36,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No events yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Student entry and exit activity will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFE8D7C8)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...recentEvents.map((student) {
                      final isInside = student.status == 'Inside Campus';
                      final timestamp = DateTime.tryParse(student.lastSeen);
                      final timeLabel = timestamp == null
                          ? student.lastSeen
                          : timestamp.toLocal().toString().substring(0, 16);
                      final accent = isInside
                          ? const Color(0xFF8FC99A)
                          : const Color(0xFFE7B77A);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D2017),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF68432D)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: accent.withValues(alpha: 0.18),
                            child: Icon(
                              isInside
                                  ? Icons.login_rounded
                                  : Icons.logout_rounded,
                              color: accent,
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${student.status}  •  ${student.grade}',
                            style: const TextStyle(color: Color(0xFFE8D7C8)),
                          ),
                          trailing: Text(
                            timeLabel,
                            style: const TextStyle(
                              color: Color(0xFFE7B77A),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      case 'reports':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2017),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB38157)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Daily campus attendance and activity summary',
                  style: TextStyle(color: Color(0xFFE8D7C8)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.login,
                        title: '6',
                        subtitle: 'Total Entries',
                        color: const Color(0xFF5DBF7A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.logout,
                        title: '2',
                        subtitle: 'Total Exits',
                        color: const Color(0xFFE09A58),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case 'notifications':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2017),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB38157)),
            ),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _selectedSection = 'messages'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D2017),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFB38157)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7B77A),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Image.asset(
                            'assets/sfhsi.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Parent message received',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'messages':
        return _buildAdminMessageSection();

      case 'settings':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Manage your administrator profile and sign-in details.',
                    style: TextStyle(color: Color(0xFFE8D7C8)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF68432D), Color(0xFF3D2017)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFB38157)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFFE7B77A),
                          child: Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFF3A1C10),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _adminName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _adminEmail,
                                style: const TextStyle(
                                  color: Color(0xFFE8D7C8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Administrator account',
                                style: TextStyle(
                                  color: Color(0xFFE7B77A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Profile & security',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildAdminSettingTile(
                    icon: Icons.person_outline,
                    title: 'Name',
                    subtitle: 'Update the name shown on your admin profile',
                    onTap: _promptAdminChangeName,
                  ),
                  const SizedBox(height: 10),
                  _buildAdminSettingTile(
                    icon: Icons.alternate_email,
                    title: 'Email address',
                    subtitle: _adminEmail,
                    onTap: _promptAdminChangeEmail,
                  ),
                  const SizedBox(height: 10),
                  _buildAdminSettingTile(
                    icon: Icons.lock_outline,
                    title: 'Password',
                    subtitle: 'Change your account password',
                    onTap: _promptAdminChangePassword,
                  ),
                ],
              ),
            ),
          ),
        );
      default:
        return SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.people,
                        title: _totalStudents.toString(),
                        subtitle: 'Total Students',
                        color: const Color(0xFFB38157),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.apartment,
                        title: _currentlyInside.toString(),
                        subtitle: 'Currently Inside',
                        color: const Color(0xFFB38157),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.login,
                        title: _totalEntries.toString(),
                        subtitle: 'Total Entries',
                        color: const Color(0xFFB38157),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.logout,
                        title: _totalExits.toString(),
                        subtitle: 'Total Exits',
                        color: const Color(0xFFB38157),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStudentFilterSection(),
            ],
          ),
        );
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
          ParentAccountService().logout();
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF3A1C10),
        drawer: _buildAdminDrawer(),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3A1C10),
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SFHSI Admin Dashboard',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                'Entry & Exit Monitoring System',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          actions: [_buildNotificationActionButton()],
        ),
        body: ColoredBox(
          color: const Color(0xFF3A1C10),
          child: _buildAdminMainBody(),
        ),
      ),
    );
  }

  Widget _buildStudentFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3D2017),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB38157), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.people_alt, color: Color(0xFFE7B77A)),
                SizedBox(width: 8),
                Text(
                  'Filter by Grade',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _grades.length,
                itemBuilder: (context, index) {
                  final grade = _grades[index];
                  final selected = grade == _selectedGrade;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(
                        grade,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFFE7B77A),
                      backgroundColor: const Color(0xFF5B3A24),
                      onSelected: (_) {
                        setState(() {
                          _selectedGrade = grade;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndStatusSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registered Students',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or student ID...',
                    hintStyle: const TextStyle(color: Color(0xFFE8D7C8)),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFE7B77A),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF3D2017),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB38157)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB38157)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<LogStatus>(
                  dropdownColor: const Color(0xFF3D2017),
                  style: const TextStyle(color: Colors.white),
                  initialValue: _selectedLogStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF3D2017),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB38157)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB38157)),
                    ),
                  ),
                  items: LogStatus.values
                      .map(
                        (s) => DropdownMenuItem<LogStatus>(
                          value: s,
                          child: Text(
                            s.toString().split('.').last,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedLogStatus = v ?? LogStatus.all),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoStudentState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF3D2017),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB38157)),
        ),
        child: Column(
          children: const [
            Icon(Icons.info_outline, size: 36, color: Color(0xFFE7B77A)),
            SizedBox(height: 8),
            Text(
              'No students are registered in the database yet.',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTable() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.brown[600]!, width: 2),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 1, child: _buildTableHeader('ID')),
                Expanded(flex: 2, child: _buildTableHeader('Student')),
                Expanded(flex: 1, child: _buildTableHeader('Grade')),
                Expanded(flex: 2, child: _buildTableHeader('Parent')),
                Expanded(flex: 1, child: _buildTableHeader('Status')),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: _filteredStudents
                .map((student) => _buildTableRow(student))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.green[700],
      ),
    );
  }

  Widget _buildEventSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2017),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF68432D)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(label, style: const TextStyle(color: Color(0xFFE8D7C8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF3D2017),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF68432D)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(
                  0xFFE7B77A,
                ).withValues(alpha: 0.16),
                child: Icon(icon, color: const Color(0xFFE7B77A)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFE8D7C8),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFE7B77A)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2017),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFFE8D7C8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(AdminStudent student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              student.id,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: student.imageUrl.isEmpty
                      ? null
                      : NetworkImage(student.imageUrl),
                  child: Text(student.name.isNotEmpty ? student.name[0] : '?'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        student.section,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.brown[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                student.grade,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.brown[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.parent,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  student.parentEmail,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.brown[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                student.status,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.brown[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  void _handleLogout() {
    if (!mounted) return;
    () async {
      final should = await _confirmLogoutOnBack();
      if (should && mounted) {
        ParentAccountService().logout();
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }();
  }
}
