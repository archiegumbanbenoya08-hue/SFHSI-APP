import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import 'backend_api_service.dart';
import 'push_notification_display_stub.dart'
    if (dart.library.html) 'push_notification_display_web.dart'
    if (dart.library.io) 'push_notification_display_native.dart' as display;

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();
  static const _webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');
  FirebaseMessaging? _messaging;
  String? _installationId;

  Future<bool> initialize() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) return false;
    await Firebase.initializeApp(options: options);
    _messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    await FirebaseMessaging.instance.requestPermission();
    if (kIsWeb) {
      await FirebaseMessaging.instance.getToken(
        vapidKey: _webVapidKey.isEmpty ? null : _webVapidKey,
      ).then((value) => _installationId = value);
    } else {
      _installationId = await FirebaseMessaging.instance.getToken();
    }
    return _installationId != null;
  }

  Future<void> registerCurrentDevice() async {
    if (_installationId == null) await initialize();
    if (_installationId == null) return;
    final user = BackendApiService.instance.currentUser;
    if (user?.role == 'parent') {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('attendance_notifications_${user!.id}') == false) return;
    }
    await BackendApiService.instance.registerPushDevice(_installationId!);
  }

  Future<void> unregisterCurrentDevice() async {
    if (_installationId == null) return;
    await BackendApiService.instance.unregisterPushDevice(_installationId!);
  }

  Future<bool> parentNotificationsEnabled(int parentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('attendance_notifications_$parentId') ?? true;
  }

  Future<void> setParentNotificationsEnabled(int parentId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('attendance_notifications_$parentId', enabled);
    if (enabled) {
      await registerCurrentDevice();
    } else {
      await unregisterCurrentDevice();
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'Campus ENTRY/EXIT update';
    final body = message.notification?.body ??
        '${message.data['student_name'] ?? 'A student'} attendance was updated.';
    display.showPushNotification(title, body);
  }
}
