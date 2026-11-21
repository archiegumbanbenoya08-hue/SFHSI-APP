// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sfhsi_app/main.dart';
import 'package:sfhsi_app/pages/parent_page.dart';
import 'package:sfhsi_app/services/app_connection_service.dart';
import 'package:sfhsi_app/services/parent_account_service.dart';

void main() {
  testWidgets('App starts and shows welcome page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome to SFHSI System'), findsOneWidget);
  });

  testWidgets('Parent page renders without notification crash', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: ParentPage()));
    expect(find.byType(ParentPage), findsOneWidget);
  });

  test('Last email and profile image path remain local preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ParentAccountService();

    await service.setLastLoggedInEmail('parent@example.com');
    await service.saveProfileImagePath(
      'parent@example.com',
      'profile.png',
    );

    expect(await service.getProfileImagePath('parent@example.com'), 'profile.png');
    expect(await service.getLastLoggedInEmail(), 'parent@example.com');
  });

  test('Password validation enforces minimum length and no whitespace', () {
    final service = ParentAccountService();
    expect(service.validatePassword('validpass123'), isTrue);
    expect(service.validatePassword('short'), isFalse);
    expect(service.validatePassword('has space 123'), isFalse);
  });

  test(
    'Offline gate blocks app usage when the connection is unavailable',
    () async {
      AppConnectionService.forceOffline = true;
      try {
        expect(await AppConnectionService().canUseApp(), isFalse);
      } finally {
        AppConnectionService.forceOffline = false;
      }
    },
  );
}
