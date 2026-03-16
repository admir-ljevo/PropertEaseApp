import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/base_provider.dart';
import 'package:propertease_admin/utils/authorization.dart';

class UserProvider with ChangeNotifier {
  static String get _baseUrl => AppConfig.apiBase;
  late String _endpoint;
  Map<String, String> createHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = Authorization.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  UserProvider() {
    _endpoint = 'ApplicationUser';
  }
  bool isValidResponse(Response response) {
    if (response.statusCode < 299) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Wrong credentials");
    } else {
      throw Exception("Something else is wrong");
    }
  }

  Future<void> deleteById(int? id) async {
    var url = "$_baseUrl$_endpoint/$id";
    final headers = createHeaders();

    final response = await http.delete(Uri.parse(url), headers: headers);
    print(url);
    if (response.statusCode == 200) {
      print("User deleted successfully");
    } else if (response.statusCode == 404) {
      throw Exception("User not found");
    } else {
      // Handle other error cases
      throw Exception(
          "Failed to delete user. Status code: ${response.statusCode}");
    }
  }

  Future<List<ApplicationUser>> getAllUsers() async {
    var url = '$_baseUrl$_endpoint/GetAllUsers';
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    List<ApplicationUser> users = [];
    if (isValidResponse(response)) {
      return (jsonDecode(response.body) as List)
          .map((item) => ApplicationUser.fromJson(item))
          .toList();
    }
    throw Exception("Something is wrong");
  }

  Future<ApplicationUser> GetEmployeeById(int id) async {
    var url = '${AppConfig.apiBase}Employee/$id';
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      ApplicationUser user = ApplicationUser.fromJson(responseData);
      return user;
    } else {
      throw Exception("Something is wrong");
    }
  }

  Future<List<ApplicationUser>> getEmployees() async {
    var url = '${AppConfig.apiBase}Employee/Get';
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    try {
      if (isValidResponse(response)) {
        return (jsonDecode(response.body) as List)
            .map((item) => ApplicationUser.fromJson(item))
            .toList();
      } else {
        throw Exception("Not valid response: ");
      }
    } catch (e) {
      throw Exception(response.statusCode);
    }
  }

  Future<SearchResult<ApplicationUser>> get({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint/GetFilteredData";

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    try {
      if (isValidResponse(response)) {
        final decoded = jsonDecode(response.body);
        final List items = decoded['items'] as List;
        final result = SearchResult<ApplicationUser>();
        result.totalCount = (decoded['totalCount'] as int?) ?? 0;
        result.count = items.length;
        result.result =
            items.map((item) => ApplicationUser.fromJson(item)).toList();
        return result;
      } else {
        throw Exception("Not valid response");
      }
    } catch (e) {
      throw Exception(response.statusCode);
    }
  }

  Future<Map<String, dynamic>?> signIn(String userName, String password) async {
    try {
      final url = Uri.parse('${AppConfig.apiBase}Access/SignIn');
      final response = await http.post(
        url,
        body: jsonEncode({
          'userName': userName,
          'password': password,
          'rememberMe': false,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        // Successful login
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String accessToken = data['token'];
        final List<dynamic> userRoles = data['user']['userRoles'];
        final String userId = data['user']['id'].toString();
        final String firstName = data['user']['person']['firstName'];
        final String lastName = data['user']['person']['lastName'];
        final String profilePhoto = data['user']['person']['profilePhoto'];
        late int roleId;

        // Check if there is a userRole with role['id'] equal to 3
        bool hasAdminRole =
            userRoles.any((userRole) => userRole['role']['id'] == 1);

        bool hasEmployeeRole =
            userRoles.any((userRole) => userRole['role']['id'] == 3);

        if (hasAdminRole) {
          roleId = 1;
          return {
            'accessToken': accessToken,
            'userId': userId,
            'firstName': firstName,
            'lastName': lastName,
            'profilePhoto': profilePhoto,
            'roleId': roleId,
          };
        } else if (hasEmployeeRole) {
          roleId = 3;
          return {
            'accessToken': accessToken,
            'userId': userId,
            'firstName': firstName,
            'lastName': lastName,
            'profilePhoto': profilePhoto,
            'roleId': roleId,
          };
        }
        return null;
      }
    } catch (e) {
      return null;
    }

    return null; // Return null if the login fails or there's an error
  }

  Future<void> addClient(ApplicationUser client, String password) async {
    try {
      final url = Uri.parse('${AppConfig.apiBase}Clients/Add');
      final request = http.MultipartRequest('POST', url);
      request.fields['Id'] = client.id.toString();
      request.fields['Email'] = client.email ?? '';
      request.fields['UserName'] = client.userName ?? '';
      request.fields['FirstName'] = client.person?.firstName ?? '';
      request.fields['LastName'] = client.person?.lastName ?? '';
      request.fields['BirthDate'] =
          client.person?.birthDate?.toIso8601String() ?? '';
      request.fields['Gender'] = client.person?.gender?.toString() ?? '';
      request.fields['ProfilePhoto'] = client.person?.profilePhoto ?? '';
      request.fields['ProfilePhotoThumbnail'] =
          client.person?.profilePhotoThumbnail ?? '';
      request.fields['BirthPlaceId'] =
          client.person?.birthPlaceId?.toString() ?? '';
      request.fields['Jmbg'] = client.person?.jmbg ?? '';
      request.fields['PlaceOfResidenceId'] =
          client.person?.placeOfResidenceId?.toString() ?? '';

      request.fields['Address'] = client.person?.address ?? '';
      request.fields['PostCode'] = client.person?.postCode ?? '';
      request.fields['PhoneNumber'] = client.phoneNumber ?? '';
      request.fields['Password'] = password;
      if (client.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('File', client.file!.path,
              contentType: http_parser.MediaType('image', 'jpeg')),
        );
      }
      final response = await request.send();
      if (response.statusCode != 200) {
        print('Error: ${response.statusCode} ${response.toString()}');
      }
    } catch (e) {
      print('Err: ${e.toString()}');
    }
  }

  Future<void> addEmployee(ApplicationUser employee, String password,
      {int? roleId}) async {
    try {
      final url = Uri.parse('${AppConfig.apiBase}Employee/Add');
      final request = http.MultipartRequest('POST', url);
      request.fields['Id'] = employee.id.toString();
      request.fields['Email'] = employee.email ?? '';
      request.fields['UserName'] = employee.userName ?? '';
      request.fields['FirstName'] = employee.person?.firstName ?? '';
      request.fields['LastName'] = employee.person?.lastName ?? '';
      request.fields['BirthDate'] =
          employee.person?.birthDate?.toIso8601String() ?? '';
      request.fields['Gender'] = employee.person?.gender?.toString() ?? '';
      request.fields['ProfilePhoto'] = employee.person?.profilePhoto ?? '';
      request.fields['ProfilePhotoThumbnail'] =
          employee.person?.profilePhotoThumbnail ?? '';
      request.fields['BirthPlaceId'] =
          employee.person?.birthPlaceId?.toString() ?? '';
      request.fields['Jmbg'] = employee.person?.jmbg ?? '';
      request.fields['PlaceOfResidenceId'] =
          employee.person?.placeOfResidenceId?.toString() ?? '';
      request.fields['MarriageStatus'] =
          employee.person?.marriageStatus?.toString() ?? '';
      request.fields['Nationality'] = employee.person?.nationality ?? '';
      request.fields['Citizenship'] = employee.person?.citizenship ?? '';
      request.fields['Address'] = employee.person?.address ?? '';
      request.fields['PostCode'] = employee.person?.postCode ?? '';
      request.fields['PhoneNumber'] = employee.phoneNumber ?? '';
      request.fields['Password'] = password;
      if (roleId != null) request.fields['RoleId'] = roleId.toString();

      if (employee.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('File', employee.file!.path,
              contentType: http_parser.MediaType('image', 'jpeg')),
        );
      }
      final response = await request.send();
      if (response.statusCode != 200) {
        print('Error: ${response.statusCode} ${response.toString()}');
      }
    } catch (e) {
      print('Err: ${e.toString()}');
    }
  }

  Future<void> updateClient(ApplicationUser client, int id) async {
    try {
      final url = Uri.parse('${AppConfig.apiBase}Clients/Edit/$id');
      final request = http.MultipartRequest('PUT', url);
      request.fields['Id'] = client.id.toString();
      request.fields['Email'] = client.email ?? '';
      request.fields['UserName'] = client.userName ?? '';
      request.fields['FirstName'] = client.person?.firstName ?? '';
      request.fields['LastName'] = client.person?.lastName ?? '';
      request.fields['BirthDate'] =
          client.person?.birthDate?.toIso8601String() ?? '';
      request.fields['Gender'] = client.person?.gender?.toString() ?? '';
      request.fields['ProfilePhoto'] = client.person?.profilePhoto ?? '';
      request.fields['ProfilePhotoThumbnail'] =
          client.person?.profilePhotoThumbnail ?? '';
      request.fields['BirthPlaceId'] =
          client.person?.birthPlaceId?.toString() ?? '';
      request.fields['Jmbg'] = client.person?.jmbg ?? '';
      request.fields['PlaceOfResidenceId'] =
          client.person?.placeOfResidenceId?.toString() ?? '';

      request.fields['Address'] = client.person?.address ?? '';
      request.fields['PostCode'] = client.person?.postCode ?? '';
      request.fields['PhoneNumber'] = client.phoneNumber ?? '';

      if (client.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('File', client.file!.path,
              contentType: http_parser.MediaType('image', 'jpeg')),
        );
      }
      final response = await request.send();
      if (response.statusCode != 200) {
        print('Error: ${response.statusCode} ${response.toString()}');
      }
    } catch (e) {
      print('Err: ${e.toString()}');
    }
  }

  Future<void> updateEmployee(ApplicationUser employee, int id) async {
    try {
      final url = Uri.parse('${AppConfig.apiBase}Employee/Edit/$id');
      final request = http.MultipartRequest('PUT', url);

      request.fields['Id'] = employee.id.toString();
      request.fields['Email'] = employee.email ?? '';
      request.fields['UserName'] = employee.userName ?? '';
      request.fields['FirstName'] = employee.person?.firstName ?? '';
      request.fields['LastName'] = employee.person?.lastName ?? '';
      if (employee.person?.birthDate != null) {
        request.fields['BirthDate'] =
            employee.person!.birthDate!.toIso8601String();
      }
      if (employee.person?.gender != null) {
        request.fields['Gender'] = employee.person!.gender!.toString();
      }
      request.fields['ProfilePhoto'] = employee.person?.profilePhoto ?? '';
      request.fields['ProfilePhotoThumbnail'] =
          employee.person?.profilePhotoThumbnail ?? '';
      if (employee.person?.birthPlaceId != null) {
        request.fields['BirthPlaceId'] =
            employee.person!.birthPlaceId!.toString();
      }
      request.fields['Jmbg'] = employee.person?.jmbg ?? '';
      if (employee.person?.placeOfResidenceId != null) {
        request.fields['PlaceOfResidenceId'] =
            employee.person!.placeOfResidenceId!.toString();
      }
      if (employee.person?.marriageStatus != null) {
        request.fields['MarriageStatus'] =
            employee.person!.marriageStatus!.toString();
      }
      request.fields['Nationality'] = employee.person?.nationality ?? '';
      request.fields['Citizenship'] = employee.person?.citizenship ?? '';
      request.fields['Address'] = employee.person?.address ?? '';
      request.fields['PostCode'] = employee.person?.postCode ?? '';
      request.fields['PhoneNumber'] = employee.phoneNumber ?? '';

      if (employee.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('File', employee.file!.path,
              contentType: http_parser.MediaType('image', 'jpeg')),
        );
      }

      final response = await request.send();
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        print('updateEmployee error ${response.statusCode}: $body');
        throw Exception('updateEmployee failed ${response.statusCode}: $body');
      }
    } catch (e) {
      print('Err: ${e.toString()}');
    }
  }

  /// Fetches a single user by ID via the Employee endpoint (works for all roles).
  Future<ApplicationUser> getById(int id) async {
    final url = Uri.parse('${AppConfig.apiBase}Employee/$id');
    final response = await http.get(url, headers: createHeaders());
    if (isValidResponse(response)) {
      return ApplicationUser.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load user $id');
  }

  /// Updates the logged-in user's own profile and refreshes Authorization cache.
  Future<void> updateProfile(ApplicationUser user) async {
    if (Authorization.roleId == 3 || Authorization.role == 'Client') {
      await updateClient(user, user.id!);
    } else {
      await updateEmployee(user, user.id!);
    }
    Authorization.firstName = user.person?.firstName;
    Authorization.lastName = user.person?.lastName;
  }

  Future<void> changePassword(
      int userId, String currentPassword, String newPassword) async {
    final url = Uri.parse('${AppConfig.apiBase}Access/ChangePassword');
    final response = await http.post(
      url,
      headers: createHeaders(),
      body: jsonEncode({
        'userId': userId.toString(),
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getUserRoles(int userId) async {
    final url = Uri.parse('${_baseUrl}ApplicationUser/$userId/roles');
    final response = await http.get(url, headers: createHeaders());
    if (isValidResponse(response)) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body) as List);
    }
    throw Exception('Failed to get user roles');
  }

  Future<void> assignRole(int userId, int roleId) async {
    final url = Uri.parse('${_baseUrl}ApplicationUser/$userId/roles');
    final response = await http.post(
      url,
      headers: createHeaders(),
      body: jsonEncode({'userId': userId, 'roleId': roleId}),
    );
    if (response.statusCode >= 300) {
      throw Exception('Failed to assign role: ${response.statusCode}');
    }
  }

  Future<void> removeUserRole(int userId, int roleId) async {
    final url = Uri.parse('${_baseUrl}ApplicationUser/$userId/roles/$roleId');
    final response = await http.delete(url, headers: createHeaders());
    if (response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> adminResetPassword(int userId, String newPassword) async {
    final url = Uri.parse('${_baseUrl}Access/AdminResetPassword');
    final headers = createHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'userId': userId.toString(), 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reset password: ${response.statusCode}');
    }
  }

  String getQueryString(Map params, {String prefix = '&'}) {
    String query = '';
    params.forEach((key, value) {
      if (value != null) {
        if (value is String ||
            value is int ||
            value is double ||
            value is bool) {
          var encoded = Uri.encodeComponent(value.toString());
          query += '$prefix$key=$encoded';
        } else if (value is DateTime) {
          query += '$prefix$key=${value.toIso8601String()}';
        } else if (value is List) {
          for (var item in value) {
            query += getQueryString({key: item}, prefix: '$prefix$key[]');
          }
        } else if (value is Map) {
          query += getQueryString(value, prefix: '$prefix$key.');
        }
      }
    });
    return query;
  }
}
