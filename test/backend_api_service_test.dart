import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sfhsi_app/services/backend_api_service.dart';

void main() {
  test('Login token authenticates database list requests', () async {
    final api = BackendApiService(
      baseUrl: 'https://api.example.test/api',
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {
            'email': 'parent@example.com',
            'password': 'secret',
          });
          return http.Response(
            jsonEncode({
              'id': 42,
              'email': 'parent@example.com',
              'name': 'Parent Example',
              'role': 'parent',
              'token': 'test-token',
            }),
            200,
          );
        }

        expect(request.url.path, '/api/parents');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode([
            {'id': 5, 'email': 'other@example.com', 'name': 'Other Parent'},
          ]),
          200,
        );
      }),
    );

    final user = await api.login(' parent@example.com ', 'secret');
    final parents = await api.getParents();

    expect(user.role, 'parent');
    expect(user.id, 42);
    expect(parents.single['email'], 'other@example.com');
  });

  test('Login errors preserve the server status and message', () async {
    final api = BackendApiService(
      baseUrl: 'https://api.example.test/api',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'Invalid email or password'}),
          401,
        ),
      ),
    );

    await expectLater(
      api.login('parent@example.com', 'wrong'),
      throwsA(
        isA<BackendApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having(
              (error) => error.message,
              'message',
              'Invalid email or password',
            ),
      ),
    );
  });

  test('Parent email verification and Google sign-up use public endpoints', () async {
    final requests = <http.Request>[];
    final api = BackendApiService(
      baseUrl: 'https://api.example.test/api',
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/auth/register') {
          return http.Response(
            jsonEncode({
              'verification_required': true,
              'email': 'parent@example.com',
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'id': 23,
            'email': 'parent@example.com',
            'name': 'Parent',
            'role': 'parent',
            'token': 'parent-token',
          }),
          200,
        );
      }),
    );

    final email = await api.requestParentSignup(
      name: 'Parent',
      email: 'parent@example.com',
      password: 'safe-password',
    );
    expect(email, 'parent@example.com');
    final verifiedUser = await api.verifyParentEmail(
      email: email,
      code: '123456',
    );
    await api.signInWithGoogle('verified-google-id-token');

    expect(requests[0].url.path, '/api/auth/register');
    expect(requests[0].headers.containsKey('Authorization'), isFalse);
    expect(jsonDecode(requests[0].body), {
      'name': 'Parent',
      'email': 'parent@example.com',
      'password': 'safe-password',
    });
    expect(requests[1].url.path, '/api/auth/verify-email');
    expect(requests[1].headers.containsKey('Authorization'), isFalse);
    expect(jsonDecode(requests[1].body), {
      'email': 'parent@example.com',
      'code': '123456',
    });
    expect(verifiedUser.role, 'parent');
    expect(requests[2].url.path, '/api/auth/google');
    expect(requests[2].headers.containsKey('Authorization'), isFalse);
    expect(jsonDecode(requests[2].body), {
      'id_token': 'verified-google-id-token',
    });
  });

  test('Admin statistics use the authenticated API and parse daily counts', () async {
    final requests = <http.Request>[];
    final api = BackendApiService(
      baseUrl: 'https://api.example.test/api',
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'email': 'admin@example.com',
              'name': 'Admin',
              'role': 'admin',
              'token': 'admin-token',
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'totalStudents': 25,
            'studentsOnCampus': 8,
            'entriesToday': 12,
            'exitsToday': 4,
          }),
          200,
        );
      }),
    );

    await api.login('admin@example.com', 'secret');
    final statistics = await api.getAdminStatistics();

    expect(requests[1].method, 'GET');
    expect(requests[1].url.path, '/api/admin/statistics');
    expect(requests[1].headers['Authorization'], 'Bearer admin-token');
    expect(statistics.totalStudents, 25);
    expect(statistics.studentsOnCampus, 8);
    expect(statistics.entriesToday, 12);
    expect(statistics.exitsToday, 4);
  });

  test(
    'Push device registration and removal use the authenticated session',
    () async {
      final requests = <http.Request>[];
      final api = BackendApiService(
        baseUrl: 'https://api.example.test/api',
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/auth/login') {
            return http.Response(
              jsonEncode({
                'id': 42,
                'email': 'parent@example.com',
                'name': 'Parent Example',
                'role': 'parent',
                'token': 'test-token',
              }),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );

      await api.login('parent@example.com', 'secret');
      await api.registerPushDevice('test-fcm-installation-id-1234567890');
      await api.unregisterPushDevice('test-fcm-installation-id-1234567890');

      expect(requests[1].method, 'PUT');
      expect(requests[1].headers['Authorization'], 'Bearer test-token');
      expect(jsonDecode(requests[1].body), {
        'fcm_installation_id': 'test-fcm-installation-id-1234567890',
      });
      expect(requests[2].method, 'DELETE');
      expect(requests[2].headers['Authorization'], 'Bearer test-token');
    },
  );
}
