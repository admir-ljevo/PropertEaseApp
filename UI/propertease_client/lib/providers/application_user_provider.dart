import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:http/io_client.dart';

import '../models/application_user.dart';

class UserProvider with ChangeNotifier {
  static String? _baseUrl;
  late String _endpoint;
  HttpClient client = HttpClient();
  IOClient? ioClient;
  Map<String, String> createHeaders() {
    var headers = {
      'Content-Type': 'application/json; charset=utf-8',
      // "Authorization": basicAuth,
    };
    return headers;
  }

  UserProvider() {
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://10.0.2.2:7137/api/");
    _endpoint = 'ApplicationUser';
    client.badCertificateCallback = (cert, host, port) {
      return true; // Disable certificate validation (for debugging purposes).
    };
    ioClient = IOClient(client);
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

    final response = await ioClient?.delete(Uri.parse(url), headers: headers);
    print(url);
    if (response!.statusCode == 200) {
      print("User deleted successfully");
    } else if (response.statusCode == 404) {
      throw Exception("User not found");
    } else {
      // Handle other error cases
      throw Exception(
          "Failed to delete user. Status code: ${response.statusCode}");
    }
  }

  Future<String?> changePassword(
      String oldPassword, String newPassword, String userId) async {
    var url =
        'https://10.0.2.2:7137/Access/ChangePassword'; // Adjust the URL as needed

    var body = {
      'currentPassword': oldPassword,
      'newPassword': newPassword,
      'userId': userId,
    };

    var headers = createHeaders();

    try {
      final response = await ioClient?.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response?.statusCode == 200) {
        return "Password changed successfully";
      } else {
        final responseJson = json.decode(response!.body);
        return responseJson['description']; // Return the error description
      }
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }

  Future<List<ApplicationUser>> getAllUsers() async {
    var url = '$_baseUrl$_endpoint/GetAllUsers';
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await ioClient?.get(uri, headers: headers);

    List<ApplicationUser> users = [];
    if (isValidResponse(response!)) {
      return (jsonDecode(response.body) as List)
          .map((item) => ApplicationUser.fromJson(item))
          .toList();
    }
    throw Exception("Something is wrong");
  }

  Future<ApplicationUser> getClientById(int id) async {
    var url = 'https://10.0.2.2:7137/api/Clients/$id';
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await ioClient?.get(uri, headers: headers);

    if (isValidResponse(response!)) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      ApplicationUser user = ApplicationUser.fromJson(responseData);
      print("Džamija");
      return user;
    } else {
      throw Exception("Something is wrong");
    }
  }

  Future<ApplicationUser> GetEmployeeById(int id) async {
    var url = 'https://localhost:44340/api/Employee/$id';
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await ioClient?.get(uri, headers: headers);

    if (isValidResponse(response!)) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      ApplicationUser user = ApplicationUser.fromJson(responseData);
      return user;
    } else {
      throw Exception("Something is wrong");
    }
  }

  Future<List<ApplicationUser>> getEmployees() async {
    var url = 'https://localhost:44340/api/Employee/Get';
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await ioClient?.get(uri, headers: headers);

    try {
      if (isValidResponse(response!)) {
        return (jsonDecode(response.body) as List)
            .map((item) => ApplicationUser.fromJson(item))
            .toList();
      } else {
        throw Exception("Not valid response: ");
      }
    } catch (e) {
      throw Exception(response!.statusCode);
    }
  }

  Future<List<ApplicationUser>> get({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint/GetFilteredData";

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await ioClient?.get(uri, headers: headers);
    print(url);

    try {
      if (isValidResponse(response!)) {
        return (jsonDecode(response.body) as List)
            .map((item) => ApplicationUser.fromJson(item))
            .toList();
      } else {
        throw Exception("Not valid response: ");
      }
    } catch (e) {
      throw Exception(response!.statusCode);
    }
  }

  Future<Map<String, dynamic>?> signIn(String userName, String password) async {
    try {
      final url = Uri.parse("https://10.0.2.2:7137/Access/SignIn");
      var headers = createHeaders();
      final response = await ioClient!.post(
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
        String? profilePhoto = "";

        // Successful login
        final Map<String, dynamic> data = jsonDecode(response!.body);
        final String accessToken = data['token'];
        final List<dynamic> userRoles = data['user']['userRoles'];
        final String userId = data['user']['id'].toString();

        final String firstName = data['user']['person']['firstName'];
        final String lastName = data['user']['person']['lastName'];
        if (data['user']['person']['profilePhotoBytes'].toString().isNotEmpty)
          profilePhoto = data['user']['person']['profilePhotoBytes'].toString();
        print(profilePhoto);
        late int roleId;

        // Check if there is a userRole with role['id'] equal to 3

        bool isClient =
            userRoles.any((userRole) => userRole['role']['id'] == 4);
        if (isClient) {
          roleId = 4;
          return {
            'accessToken': accessToken,
            'firstName': firstName,
            'lastName': lastName,
            'profilePhoto': profilePhoto,
            'userId': userId,
            'roleId': roleId,
          };
        }
        return null;
      }
    } catch (e) {
      print(e.toString());
    }

    return null; // Return null if the login fails or there's an error
  }

  Future<void> addClient(ApplicationUser clientData, String password) async {
    try {
      final url = Uri.parse("https://10.0.2.2:7137/api/Clients/Add");

      final request = http.MultipartRequest('POST', url);

      request.fields['Id'] = clientData.id.toString();
      request.fields['Email'] = clientData.email ?? '';
      request.fields['UserName'] = clientData.userName ?? '';
      request.fields['FirstName'] = clientData.person?.firstName ?? '';
      request.fields['LastName'] = clientData.person?.lastName ?? '';
      request.fields['BirthDate'] =
          clientData.person?.birthDate?.toIso8601String() ?? '';
      request.fields['Gender'] = clientData.person?.gender?.toString() ?? '';
      request.fields['ProfilePhoto'] = clientData.person?.profilePhoto ?? '';
      request.fields['ProfilePhotoThumbnail'] =
          clientData.person?.profilePhotoThumbnail ?? '';
      request.fields['BirthPlaceId'] =
          clientData.person?.birthPlaceId?.toString() ?? '';
      request.fields['Jmbg'] = clientData.person?.jmbg ?? '';
      request.fields['PlaceOfResidenceId'] =
          clientData.person?.placeOfResidenceId?.toString() ?? '';

      request.fields['Address'] = clientData.person?.address ?? '';
      request.fields['PostCode'] = clientData.person?.postCode ?? '';
      request.fields['PhoneNumber'] = clientData.phoneNumber ?? '';
      request.fields['Position'] = clientData.person?.position.toString() ?? '';
      request.fields['Password'] = password;

      if (clientData.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('File', clientData.file!.path,
              contentType: http_parser.MediaType('image', 'jpeg')),
        );
      }

      final streamedResponse = await ioClient!.send(request);

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        print('Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Err: ${e.toString()}');
    }
  }

  Future<void> updateClient(ApplicationUser client, int id) async {
    try {
      final url = Uri.parse("https://10.0.2.2:7137/api/Clients/Edit/$id");
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
      request.fields['Position'] = client.person?.position.toString() ?? '';

      if (client.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('File', client.file!.path,
              contentType: http_parser.MediaType('image', 'jpeg')),
        );
      }
      final streamedResponse = await ioClient!.send(request);

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        print('Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Err: ${e.toString()}');
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
