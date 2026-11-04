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
}
