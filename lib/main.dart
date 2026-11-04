import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/admin_page.dart';
import 'pages/parent_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: Colors.brown,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

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
