import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';

/// HTTP client for the Users CRUD API exposed by [MockServerService].
class UsersApiService {
  UsersApiService({this.baseUrl = 'http://localhost:8080'});

  final String baseUrl;
  final _client = http.Client();

  Future<List<User>> getAll() async {
    final res = await _client.get(Uri.parse('$baseUrl/users'));
    _assertOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<User> create({
    required String name,
    required String email,
    required String role,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/users'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'role': role}),
    );
    _assertOk(res);
    return User.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<User> update({
    required String id,
    required String name,
    required String email,
    required String role,
  }) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'role': role}),
    );
    _assertOk(res);
    return User.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final res = await _client.delete(Uri.parse('$baseUrl/users/$id'));
    _assertOk(res);
  }

  void _assertOk(http.Response res) {
    if (res.statusCode >= 400) {
      final Object? decoded = jsonDecode(res.body);
      final msg = decoded is Map ? decoded['message'] as String? : null;
      throw Exception(msg ?? 'Request failed [${res.statusCode}]');
    }
  }
}
