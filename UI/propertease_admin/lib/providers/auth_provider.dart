import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/authorization.dart';

class AuthProvider with ChangeNotifier {
  static String get _baseUrl => AppConfig.apiBase;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Sends credentials to /api/Access/SignIn and stores the JWT token.
  /// Returns true on success, false on failure.
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${_baseUrl}Access/SignIn');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        Authorization.token = data['token'] as String?;
        Authorization.username = username;
        Authorization.userId = data['userId'] as int?;
        Authorization.role = data['role'] as String?;
        Authorization.roleId = data['roleId'] as int?;
        Authorization.isRenter = data['isRenter'] as bool? ?? false;

        final person =
            (data['user'] as Map<String, dynamic>?)?['person'] as Map<String, dynamic>?;
        Authorization.firstName = person?['firstName'] as String?;
        Authorization.lastName = person?['lastName'] as String?;
        Authorization.profilePhoto = person?['profilePhoto'] as String?;
        Authorization.profilePhotoBytes = person?['profilePhotoBytes'] as String?;

        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Pogrešno korisničko ime ili lozinka.';
      } else {
        _errorMessage = 'Greška pri prijavi. Pokušajte ponovo.';
      }
    } catch (e) {
      _errorMessage = 'Nije moguće spojiti se na server. Provjerite mrežu.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    Authorization.clear();
    notifyListeners();
  }
}
