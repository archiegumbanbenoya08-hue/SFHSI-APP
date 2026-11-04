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

  testWidgets('Parent page shows a no-student state by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ParentPage(email: 'parent@example.com')),
    );

    expect(find.text('No student activity yet'), findsOneWidget);
  });

  testWidgets('Parent page exposes a notification launcher', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ParentPage(email: 'parent@example.com')),
    );

    expect(find.byTooltip('Notifications'), findsOneWidget);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsWidgets);
  });

  test('Password change requires the current password', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ParentAccountService();

    await service.savePassword('parent@example.com', 'oldpass');

    final changed = await service.changePassword(
      'parent@example.com',
      currentPassword: 'wrong-pass',
      newPassword: 'newpass123',
    );

    expect(changed, isFalse);
    expect(await service.getPassword('parent@example.com'), 'oldpass');
  });

  test('Password change rejects weak passwords', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ParentAccountService();

    await service.savePassword('parent@example.com', 'oldpass');

    final changed = await service.changePassword(
      'parent@example.com',
      currentPassword: 'oldpass',
      newPassword: '123',
    );

    expect(changed, isFalse);
    expect(await service.getPassword('parent@example.com'), 'oldpass');
  });

  test('Parent email list contains the 20 parent accounts', () async {
    expect(ParentAccountService.defaultParentEmails.length, 21);
    expect(
      ParentAccountService.defaultParentEmails,
      contains('parent01@sfhsi.com'),
    );
    expect(
      ParentAccountService.defaultParentEmails,
      contains('parent20@sfhsi.com'),
    );
    expect(
      ParentAccountService.defaultParentEmails,
      contains('parent@sfhsi.com'),
    );
  });

  test('Default admin and parent credentials are not accepted', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ParentAccountService();
    expect(
      await service.verifyCredentials('admin@sfhsi.com', 'not-configured'),
      isFalse,
    );
    expect(
      await service.verifyCredentials('parent@sfhsi.com', 'not-configured'),
      isFalse,
    );
  });

  test('Updated account details persist across app restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ParentAccountService();

    await service.savePassword('parent@example.com', 'OldPass@123');
    await service.saveParentName('parent@example.com', 'Old Name');
    await service.saveProfileImagePath(
      'parent@example.com',
      '/tmp/old_profile.png',
    );
    await service.setLastLoggedInEmail('parent@example.com');

    await service.changeEmail(
      'parent@example.com',
      'newparent@example.com',
      isAdmin: false,
    );
    await service.saveParentName('newparent@example.com', 'New Parent Name');
    await service.savePassword('newparent@example.com', 'NewPass@456');
    await service.saveProfileImagePath(
      'newparent@example.com',
      '/tmp/new_profile.png',
    );

    expect(await service.getPassword('newparent@example.com'), 'NewPass@456');
    expect(
      await service.getParentName('newparent@example.com'),
      'New Parent Name',
    );
    expect(
      await service.getProfileImagePath('newparent@example.com'),
      '/tmp/new_profile.png',
    );
    expect(await service.getLastLoggedInEmail(), 'newparent@example.com');
    expect(
      await service.verifyCredentials('newparent@example.com', 'NewPass@456'),
      isTrue,
    );
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
