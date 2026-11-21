import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api_service.dart';
import 'push_notification_service.dart';
class ParentAccountService {
  static final ParentAccountService _instance =
      ParentAccountService._internal();

  factory ParentAccountService() {
    return _instance;
  }

  ParentAccountService._internal();

  static const int minimumPasswordLength = 8;
  static const String lastLoggedInEmailKey = 'last_logged_in_email';
  static const String _googleClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
  );
  static GoogleSignIn? _googleSignIn;
  static GoogleSignIn get _googleSignInClient =>
      _googleSignIn ??= GoogleSignIn(
        clientId: _googleClientId,
        serverClientId: _googleClientId,
        scopes: ['email'],
      );

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Future<BackendUser> signIn(String email, String password) async {
    final user = await BackendApiService.instance.login(email, password);
    await _finishSignIn(user);
    return user;
  }

  Future<String> requestEmailSignup({
    required String name,
    required String email,
    required String password,
  }) async {
    return BackendApiService.instance.requestParentSignup(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<BackendUser> verifyEmailSignup({
    required String email,
    required String code,
  }) async {
    final user = await BackendApiService.instance.verifyParentEmail(
      email: email,
      code: code,
    );
    await _finishSignIn(user);
    return user;
  }

  Future<BackendUser?> signInWithGoogle() async {
    if (_googleClientId.isEmpty) {
      throw const BackendApiException(
        'Google sign-in is not configured in this app build.',
      );
    }

    final account = await _googleSignInClient.signIn();
    if (account == null) return null;

    final idToken = (await account.authentication).idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const BackendApiException(
        'Google did not return an ID token. Check the OAuth client configuration.',
      );
    }

    final user = await BackendApiService.instance.signInWithGoogle(idToken);
    await _finishSignIn(user);
    return user;
  }

  Future<void> _finishSignIn(BackendUser user) async {
    final prefs = await _prefs;
    for (final key in prefs.getKeys().where((key) => key.startsWith('password_'))) {
      await prefs.remove(key);
    }
    await setLastLoggedInEmail(user.email);
    try {
      await PushNotificationService.instance.registerCurrentDevice();
    } catch (error) {
      debugPrint('Could not register push notifications: $error');
    }
  }

  Future<void> logout() async {
    try {
      await PushNotificationService.instance.unregisterCurrentDevice();
    } catch (error) {
      debugPrint('Could not unregister push notifications: $error');
    }
    if (_googleClientId.isNotEmpty) {
      try {
        await _googleSignInClient.signOut();
      } catch (error) {
        debugPrint('Could not sign out from Google: $error');
      }
    }
    BackendApiService.instance.logout();
  }

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
