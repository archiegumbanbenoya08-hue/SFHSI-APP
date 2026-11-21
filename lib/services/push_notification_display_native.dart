import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';

void showPushNotification(String title, String body) {
  unawaited(AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      channelKey: 'entry_exit_channel',
      title: title,
      body: body,
    ),
  ));
}
