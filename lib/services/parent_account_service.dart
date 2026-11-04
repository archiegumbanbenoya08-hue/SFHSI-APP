import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api_service.dart';

class ParentAccountService {
  static final ParentAccountService _instance =
      ParentAccountService._internal();

  factory ParentAccountService() {
    return _instance;
  }

  ParentAccountService._internal();

  static const int minimumPasswordLength = 8;
  static const String lastLoggedInEmailKey = 'last_logged_in_email';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Future<BackendUser> signIn(String email, String password) async {
    final user = await BackendApiService.instance.login(email, password);
    final prefs = await _prefs;
    for (final key in prefs.getKeys().where((key) => key.startsWith('password_'))) {
      await prefs.remove(key);
    }
    await setLastLoggedInEmail(user.email);
    return user;
  }

  void logout() => BackendApiService.instance.logout();

  bool validatePassword(String password) {
    final trimmedPassword = password.trim();
    return trimmedPassword.length >= minimumPasswordLength &&
        !trimmedPassword.contains(RegExp(r'\s'));
  }

  Future<String> getAdminEmail() async {
    final user = await BackendApiService.instance.getProfile();
    if (user.role != 'admin') {
      throw const BackendApiException('Administrator account required.');
    }
    return user.email;
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
    final user = await BackendApiService.instance.getProfile();
    if (_normalizeEmail(user.email) != _normalizeEmail(email)) return null;
    return user.name;
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
    try {
      await BackendApiService.instance.changePassword(
        currentPassword: currentPassword,
        newPassword: trimmedNewPassword,
      );
      return true;
    } on BackendApiException catch (error) {
      if (error.statusCode == 401) return false;
      rethrow;
    }
  }

  Future<void> saveParentName(String email, String newName) async {
    final user = await BackendApiService.instance.getProfile();
    if (_normalizeEmail(user.email) != _normalizeEmail(email)) {
      throw const BackendApiException('You can only update your own account.');
    }
    await BackendApiService.instance.updateProfile(name: newName, email: user.email);
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
    final user = await BackendApiService.instance.getProfile();
    if (_normalizeEmail(user.email) != _normalizeEmail(oldEmail) ||
        (user.role == 'admin') != isAdmin) {
      throw const BackendApiException('You can only update your own account.');
    }
    final updated = await BackendApiService.instance.updateProfile(
      name: user.name,
      email: newEmail,
    );
    await setLastLoggedInEmail(updated.email);
  }
}
