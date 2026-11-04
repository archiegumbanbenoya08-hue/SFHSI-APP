import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendApiException implements Exception {
  final int? statusCode;
  final String message;

  const BackendApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class BackendUser {
  final int id;
  final String email;
  final String name;
  final String role;

  const BackendUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory BackendUser.fromJson(Map<String, dynamic> json) => BackendUser(
    id: int.parse(json['id'].toString()),
    email: json['email'] as String,
    name: (json['name'] as String?) ?? '',
    role: json['role'] as String,
  );
}

class BackendApiService {
  BackendApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl =
          (baseUrl ??
                  const String.fromEnvironment(
                    'API_BASE_URL',
                    defaultValue: 'http://localhost:8001/api',
                  ))
              .replaceFirst(RegExp(r'/$'), '');

  static final BackendApiService instance = BackendApiService();

  final http.Client _client;
  final String _baseUrl;
  String? _token;
  BackendUser? _currentUser;

  BackendUser? get currentUser => _currentUser;

  Future<BackendUser> login(String email, String password) async {
    final response = await _request(
      'POST',
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
      authenticated: false,
    );
    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const BackendApiException('The server returned an invalid login response.');
    }
    _token = token;
    _currentUser = BackendUser.fromJson(response);
    return _currentUser!;
  }

  Future<BackendUser> getProfile() async {
    final response = await _request('GET', '/auth/profile');
    _currentUser = BackendUser.fromJson(response);
    return _currentUser!;
  }

  Future<BackendUser> updateProfile({
    required String name,
    required String email,
  }) async {
    final response = await _request(
      'PATCH',
      '/auth/profile',
      body: {'name': name.trim(), 'email': email.trim()},
    );
    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const BackendApiException('The server returned an invalid profile response.');
    }
    _token = token;
    _currentUser = BackendUser.fromJson(response);
    return _currentUser!;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _request(
      'PATCH',
      '/auth/profile/password',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getParents() =>
      _getList('/parents');

  Future<List<Map<String, dynamic>>> getStudents() =>
      _getList('/students');

  Future<List<Map<String, dynamic>>> getChildren(int parentId) =>
      _getList('/parents/$parentId/children');

  Future<List<Map<String, dynamic>>> getConversation(String email) =>
      _getList('/messages?with_email=${Uri.encodeQueryComponent(email)}');

  Future<Map<String, dynamic>> sendMessage({
    required String receiverEmail,
    required String message,
  }) => _request(
    'POST',
    '/messages',
    body: {'receiver_email': receiverEmail, 'message': message},
  );

  Future<List<Map<String, dynamic>>> getActivity({int limit = 100}) =>
      _getList('/activity/${_currentUser?.role ?? ''}?limit=$limit');

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _request('GET', path);
    final data = response['data'];
    if (data is! List) {
      throw const BackendApiException('The server returned an invalid list response.');
    }
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    if (authenticated && (_token == null || _token!.isEmpty)) {
      throw const BackendApiException('Please sign in again.');
    }

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      headers['Authorization'] = 'Bearer $_token';
    }

    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on http.ClientException catch (error) {
      throw BackendApiException('Could not connect to the server: ${error.message}');
    }

    dynamic payload;
    if (response.body.isNotEmpty) {
      try {
        payload = jsonDecode(response.body);
      } on FormatException {
        throw const BackendApiException('The server returned an invalid response.');
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = payload is Map ? payload['detail'] : null;
      throw BackendApiException(
        detail is String ? detail : 'Request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is List) {
      return {'data': payload};
    }
    if (payload == null) {
      return <String, dynamic>{};
    }
    throw const BackendApiException('The server returned an invalid response.');
  }

  void logout() {
    _token = null;
    _currentUser = null;
  }
}
