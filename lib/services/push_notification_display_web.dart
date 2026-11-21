import 'package:web/web.dart' as web;

void showPushNotification(String title, String body) {
  if (web.Notification.permission == 'granted') {
    web.Notification(title, web.NotificationOptions(body: body));
  }
}
