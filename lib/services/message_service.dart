import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String sender;
  final String receiver;
  final String text;
  final DateTime createdAt;
  final bool isAdmin;

  ChatMessage({
    required this.sender,
    required this.receiver,
    required this.text,
    required this.createdAt,
    required this.isAdmin,
  });

  Map<String, dynamic> toJson() => {
        'sender': sender,
        'receiver': receiver,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'isAdmin': isAdmin,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        sender: json['sender'] ?? '',
        receiver: json['receiver'] ?? '',
        text: json['text'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        isAdmin: json['isAdmin'] ?? false,
      );
}

class AppNotificationItem {
  final String title;
  final String message;
  final DateTime createdAt;

  AppNotificationItem({
    required this.title,
    required this.message,
    required this.createdAt,
  });
}

class MessageService {
  static const String _messagesKey = 'scmcies_messages';
  static const String _notificationsKey = 'scmcies_notifications';

  Future<List<ChatMessage>> getConversation(String currentUser, String otherUser) async {
    final all = await _loadMessages();
    final current = currentUser.trim().toLowerCase();
    final other = otherUser.trim().toLowerCase();

    return all.where((message) {
      final sender = message.sender.trim().toLowerCase();
      final receiver = message.receiver.trim().toLowerCase();
      final matchesDirect = (sender == current && receiver == other) || (sender == other && receiver == current);
      return matchesDirect;
    }).toList();
  }

  Future<List<ChatMessage>> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_messagesKey) ?? '[]';
    final decoded = jsonDecode(raw) as List;
    return decoded.map((item) => ChatMessage.fromJson(item)).toList();
  }

  Future<void> saveMessage({
    required String sender,
    required String receiver,
    required String text,
    required bool isAdmin,
  }) async {
    final sanitizedText = text.trim();
    if (sanitizedText.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final all = await _loadMessages();
    all.add(ChatMessage(
      sender: sender,
      receiver: receiver,
      text: sanitizedText,
      createdAt: DateTime.now(),
      isAdmin: isAdmin,
    ));

    await prefs.setString(_messagesKey, jsonEncode(all.map((message) => message.toJson()).toList()));
    await _pushLocalNotification(
      title: isAdmin ? 'Admin message' : 'Parent message',
      body: sanitizedText,
    );
  }

  Future<List<AppNotificationItem>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey) ?? '[]';
    final decoded = jsonDecode(raw) as List;

    return decoded.map((item) {
      return AppNotificationItem(
        title: item['title'] ?? 'New update',
        message: item['message'] ?? '',
        createdAt: DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> addNotification({required String title, required String message}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadNotifications();
    list.add(AppNotificationItem(title: title, message: message, createdAt: DateTime.now()));
    await prefs.setString(
      _notificationsKey,
      jsonEncode(list.map((item) => {
        'title': item.title,
        'message': item.message,
        'createdAt': item.createdAt.toIso8601String(),
      }).toList()),
    );
  }

  Future<void> _pushLocalNotification({required String title, required String body}) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
