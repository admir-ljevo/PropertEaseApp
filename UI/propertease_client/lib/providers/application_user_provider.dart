import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:http/io_client.dart';

import '../models/application_user.dart';
import '../utils/authorization.dart';
import 'base_provider.dart';

class UserProvider with ChangeNotifier {
  static String get _baseUrl => BaseProvider.baseUrl;
  final String _endpoint = 'ApplicationUser';

  final HttpClient _client = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;
  late final IOClient _ioClient;

  UserProvider() {
    _ioClient = IOClient(_client);
  }

  Map<String, String> _headers() {
    final h = <String, String>{'Content-Type': 'application/json; charset=utf-8'};
    if (Authorization.token != null && Authorization.token!.isNotEmpty) {
      h['Authorization'] = 'Bearer ${Authorization.token}';
    }
    return h;
  }

  bool _isValid(Response response) {
    if (response.statusCode < 300) return true;
    if (response.statusCode == 401) throw Exception('Wrong credentials');
    throw Exception('Server error ${response.statusCode}');
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  /// Returns a map with token + user info on success, or null on failure.
  Future<Map<String, dynamic>?> signIn(String userName, String password) async {
    try {
      final url = Uri.parse('${_baseUrl}Access/SignIn');
      final response = await _ioClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': userName,
          'password': password,
          'rememberMe': false,
        }),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      if (token == null || user == null) return null;

      final roleId = data['roleId'] as int?;
      final role = data['role'] as String?;
      // Allow role ID 3 (Client) or legacy role name check
      final isClient = roleId == 3 ||
          role?.toLowerCase() == 'client' ||
          role?.toLowerCase() == 'korisnik';
      if (!isClient) return null;

      final person = user['person'] as Map<String, dynamic>?;
      final photoBytes =
          person?['profilePhotoBytes']?.toString().isNotEmpty == true
              ? person!['profilePhotoBytes'].toString()
              : null;

      return {
        'token': token,
        'userId': user['id'],
        'firstName': person?['firstName'] ?? '',
        'lastName': person?['lastName'] ?? '',
        'profilePhotoBytes': photoBytes,
        'role': role,
        'roleId': roleId,
      };
    } catch (e) {
      debugPrint('signIn error: $e');
      return null;
    }
  }

  Future<String?> changePassword(
      String oldPassword, String newPassword, String userId) async {
    final url = Uri.parse('${_baseUrl}Access/ChangePassword');
    try {
      final response = await _ioClient.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'currentPassword': oldPassword,
          'newPassword': newPassword,
          'userId': userId,
        }),
      );
      if (response.statusCode == 200) return 'Password changed successfully';
      final body = jsonDecode(response.body);
      if (body is List && body.isNotEmpty) {
        final code = body.first['code'] as String? ?? '';
        if (code == 'PasswordMismatch') return 'PasswordMismatch';
        return body.first['description'] as String? ?? 'Error changing password';
      }
      return 'Error changing password';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  // ── User CRUD ───────────────────────────────────────────────────────────────

  Future<ApplicationUser> getClientById(int id) async {
    final url = Uri.parse('${_baseUrl}Clients/$id');
    final response = await _ioClient.get(url, headers: _headers());
    if (_isValid(response)) {
      return ApplicationUser.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch user');
  }

  Future<ApplicationUser> getRenterById(int id) async {
    final url = Uri.parse('${_baseUrl}Clients/$id');
    final response = await _ioClient.get(url, headers: _headers());
    if (_isValid(response)) {
      return ApplicationUser.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch renter');
  }

  Future<void> addClient(ApplicationUser clientData, String password) async {
    final url = Uri.parse('${_baseUrl}Clients/Add');
    final request = http.MultipartRequest('POST', url);
    _fillUserFields(request, clientData, password: password);
    if (clientData.file != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'File', clientData.file!.path,
          contentType: http_parser.MediaType('image', 'jpeg')));
    }
    final streamed = await _ioClient.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('addClient failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> updateClient(ApplicationUser client, int id) async {
    final url = Uri.parse('${_baseUrl}Clients/Edit/$id');
    final request = http.MultipartRequest('PUT', url);
    _fillUserFields(request, client);
    if (client.file != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'File', client.file!.path,
          contentType: http_parser.MediaType('image', 'jpeg')));
    }
    final streamed = await _ioClient.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('updateClient failed: ${response.statusCode} ${response.body}');
    }
  }

  void _fillUserFields(http.MultipartRequest req, ApplicationUser u,
      {String? password}) {
    req.fields['Id'] = u.id.toString();
    req.fields['Email'] = u.email ?? '';
    req.fields['UserName'] = u.userName ?? '';
    req.fields['FirstName'] = u.person?.firstName ?? '';
    req.fields['LastName'] = u.person?.lastName ?? '';
    req.fields['BirthDate'] =
        u.person?.birthDate?.toIso8601String() ?? '';
    req.fields['Gender'] = u.person?.gender?.toString() ?? '';
    req.fields['ProfilePhoto'] = u.person?.profilePhoto ?? '';
    req.fields['ProfilePhotoThumbnail'] =
        u.person?.profilePhotoThumbnail ?? '';
    req.fields['BirthPlaceId'] =
        u.person?.birthPlaceId?.toString() ?? '';
    req.fields['Jmbg'] = u.person?.jmbg ?? '';
    req.fields['PlaceOfResidenceId'] =
        u.person?.placeOfResidenceId?.toString() ?? '';
    req.fields['Address'] = u.person?.address ?? '';
    req.fields['PostCode'] = u.person?.postCode ?? '';
    req.fields['PhoneNumber'] = u.phoneNumber ?? '';
    if (password != null) req.fields['Password'] = password;

    // Attach auth header
    if (Authorization.token != null && Authorization.token!.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer ${Authorization.token}';
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> deleteById(int? id) async {
    final url = Uri.parse('${_baseUrl}$_endpoint/$id');
    final response = await _ioClient.delete(url, headers: _headers());
    if (response.statusCode == 404) throw Exception('User not found');
    if (response.statusCode >= 300) {
      throw Exception('Delete failed: ${response.statusCode}');
    }
  }
}
