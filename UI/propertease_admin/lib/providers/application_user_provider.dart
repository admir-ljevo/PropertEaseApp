import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/providers/base_provider.dart';

class UserProvider with ChangeNotifier {
  static String? _baseUrl;
  late String _endpoint;
  Map<String, String> createHeaders() {
    var headers = {
      'Content-Type': 'application/json; charset=utf-8',
      // "Authorization": basicAuth,
    };
    return headers;
  }

  UserProvider() {
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://localhost:44340/api/");
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
      // Successful deletion
      print("User deleted successfully");
    } else if (response.statusCode == 404) {
      // Property not found, handle as needed
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

  Future<List<ApplicationUser>> get({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint/GetFilteredData";

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);
    print(url);

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

  Future<void> updateEmployee(ApplicationUser employee, int id) async {
    try {
      final url = Uri.parse("https://localhost:44340/api/Employee/Edit/$id");
      final request = http.MultipartRequest('PUT', url);

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
      request.fields['Qualifications'] = employee.person?.qualifications ?? '';
      request.fields['PlaceOfResidenceId'] =
          employee.person?.placeOfResidenceId?.toString() ?? '';
      request.fields['MarriageStatus'] =
          employee.person?.marriageStatus?.toString() ?? '';
      request.fields['Nationality'] = employee.person?.nationality ?? '';
      request.fields['Citizenship'] = employee.person?.citizenship ?? '';
      request.fields['WorkExperience'] =
          employee.person?.workExperience.toString() ?? '';
      request.fields['Address'] = employee.person?.address ?? '';
      request.fields['PostCode'] = employee.person?.postCode ?? '';
      request.fields['PhoneNumber'] = employee.phoneNumber ?? '';
      request.fields['Biography'] = employee.person?.biography ?? '';
      request.fields['Position'] = employee.person?.position.toString() ?? '';
      request.fields['DateOfEmployment'] =
          employee.person?.dateOfEmployment!.toIso8601String() ?? '';
      request.fields['Pay'] = employee.person?.pay.toString() ?? '';

      if (employee.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('File', employee.file!.path,
              contentType: http_parser.MediaType('image', 'jpeg')),
        );
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        // Handle a successful response, if needed
      } else {
        print('Error: ${response.statusCode}');
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