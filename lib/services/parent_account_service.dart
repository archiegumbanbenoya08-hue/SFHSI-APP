import 'package:shared_preferences/shared_preferences.dart';

class ParentAccountService {
  static final ParentAccountService _instance =
      ParentAccountService._internal();

  factory ParentAccountService() {
    return _instance;
  }

  ParentAccountService._internal();

  static const int minimumPasswordLength = 8;
  static const String adminEmail = 'admin@sfhsi.com';
  static const String adminEmailKey = 'admin_current_email';
  static const String lastLoggedInEmailKey = 'last_logged_in_email';
  static final List<String> defaultParentEmails = List.generate(
    21,
    (index) => index == 0
        ? 'parent@sfhsi.com'
        : 'parent${index.toString().padLeft(2, '0')}@sfhsi.com',
    growable: false,
  );

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  bool validatePassword(String password) {
    final trimmedPassword = password.trim();
    return trimmedPassword.length >= minimumPasswordLength &&
        !trimmedPassword.contains(RegExp(r'\s'));
  }

  Future<String> getAdminEmail() async {
    final prefs = await _prefs;
    return prefs.getString(adminEmailKey) ?? adminEmail;
  }

  Future<void> _setAdminEmail(String email) async {
    final prefs = await _prefs;
    await prefs.setString(adminEmailKey, email);
  }

  Future<String?> getPassword(String email) async {
    final prefs = await _prefs;
    final key = 'password_${_normalizeEmail(email)}';
    return prefs.getString(key);
  }

  Future<String?> getProfileImagePath(String email) async {
    final prefs = await _prefs;
    final normalizedEmail = _normalizeEmail(email);
    return prefs.getString('profile_image_$normalizedEmail') ??
        prefs.getString('profile_image_$email');
  }

  Future<String> getLastLoggedInEmail() async {
    final prefs = await _prefs;
    return prefs.getString(lastLoggedInEmailKey) ?? '';
  }

  Future<void> setLastLoggedInEmail(String email) async {
    final prefs = await _prefs;
    if (email.isEmpty) {
      await prefs.remove(lastLoggedInEmailKey);
      return;
    }
    await prefs.setString(lastLoggedInEmailKey, _normalizeEmail(email));
  }

  Future<String?> getParentName(String email) async {
    final prefs = await _prefs;
    final normalizedEmail = _normalizeEmail(email);
    final key = 'name_$normalizedEmail';
    final savedName = prefs.getString(key) ?? prefs.getString('name_$email');
    if (savedName != null && savedName.isNotEmpty) {
      return savedName;
    }

    final currentAdminEmail = await getAdminEmail();
    if (normalizedEmail == _normalizeEmail(currentAdminEmail) ||
        normalizedEmail == _normalizeEmail(adminEmail)) {
      return 'Administrator';
    }

    return _deriveNameFromEmail(normalizedEmail);
  }

  Future<bool> verifyCredentials(String email, String password) async {
    try {
      final normalizedEmail = _normalizeEmail(email);
      final savedPassword = await getPassword(normalizedEmail);
      return savedPassword != null && savedPassword == password.trim();
    } catch (_) {
      return false;
    }
  }

  Future<void> savePassword(String email, String newPassword) async {
    final prefs = await _prefs;
    final normalizedEmail = _normalizeEmail(email);
    final key = 'password_$normalizedEmail';
    await prefs.setString(key, newPassword.trim());
  }

  Future<bool> changePassword(
    String email, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final trimmedEmail = _normalizeEmail(email);
    final trimmedNewPassword = newPassword.trim();
    if (trimmedEmail.isEmpty || trimmedNewPassword.isEmpty) return false;
    if (!validatePassword(trimmedNewPassword)) return false;
    if (!await verifyCredentials(trimmedEmail, currentPassword)) return false;

    await savePassword(trimmedEmail, trimmedNewPassword);
    return true;
  }

  Future<void> saveParentName(String email, String newName) async {
    final prefs = await _prefs;
    final normalizedEmail = _normalizeEmail(email);
    final key = 'name_$normalizedEmail';
    await prefs.setString(key, newName.trim());
  }

  Future<void> saveProfileImagePath(String email, String imagePath) async {
    final prefs = await _prefs;
    final normalizedEmail = _normalizeEmail(email);
    final key = 'profile_image_$normalizedEmail';
    await prefs.setString(key, imagePath);
  }

  Future<void> changeEmail(
    String oldEmail,
    String newEmail, {
    required bool isAdmin,
  }) async {
    final prefs = await _prefs;
    final normalizedOldEmail = _normalizeEmail(oldEmail);
    final normalizedNewEmail = _normalizeEmail(newEmail);

    final stringFields = ['password', 'name', 'profile_image'];
    for (final field in stringFields) {
      final oldKey = '${field}_$normalizedOldEmail';
      final altOldKey = '${field}_$oldEmail';
      final value = prefs.getString(oldKey) ?? prefs.getString(altOldKey);
      if (value != null) {
        await prefs.setString('${field}_$normalizedNewEmail', value);
      }
      await prefs.remove(oldKey);
      await prefs.remove(altOldKey);
    }

    await setLastLoggedInEmail(normalizedNewEmail);

    if (isAdmin) {
      await _setAdminEmail(normalizedNewEmail);
    }
  }

  String _deriveNameFromEmail(String email) {
    final local = email.split('@').first;
    final parts = local.split(RegExp(r'[._]'));
    return parts
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
