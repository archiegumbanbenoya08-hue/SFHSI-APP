import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/admin_page.dart';
import 'pages/parent_page.dart';
import 'services/push_notification_service.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'entry_exit_channel',
        channelName: 'Entry and Exit Alerts',
        channelDescription: 'Entry and exit notifications for the school',
        defaultColor: Colors.brown,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
  );
  await PushNotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SFHSI APP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/admin': (context) => const AdminPage(),
        '/parent': (context) => const ParentPage(),
      },
    );
  }
}
