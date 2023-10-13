import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
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
