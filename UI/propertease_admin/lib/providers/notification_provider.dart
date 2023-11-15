import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:propertease_admin/models/new.dart';

class NotificationProvider with ChangeNotifier {
  static String? _baseUrl;
  String _endpoint = 'Notification';

  NotificationProvider() {
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://localhost:7137/api/");
  }

  Map<String, String> createHeaders() {
    var headers = {
      'Content-Type': 'application/json; charset=utf-8',
      // "Authorization": basicAuth,
    };
    return headers;
  }

  Map<String, String> createHeadersForUpload() {
    var headers = {
      'Content-Type': 'multipart/form-data',
      // "Authorization": basicAuth,
    };
    return headers;
  }

  Future<void> updateNotification(New notification, int id) async {
    try {
      final url = Uri.parse('$_baseUrl$_endpoint/Edit/$id');
      final request = http.MultipartRequest('PUT', url);

      request.fields['Id'] = notification.id.toString();
      request.fields['CreatedAt'] = notification.createdAt!.toIso8601String();
      request.fields['IsDeleted'] = notification.isDeleted.toString();
      request.fields['UserId'] = notification.userId.toString();
      request.fields['TotalRecordsCount'] =
          notification.totalRecordsCount.toString();
      request.fields['Text'] = notification.text ?? '';
      request.fields['Image'] = notification.image ?? '';
      request.fields['Name'] = notification.name ?? '';
      if (notification.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', notification.file!.path,
              contentType: http_parser.MediaType(
                  'image', 'jpeg')), // Set content type as needed
        );
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        // Photo uploaded successfully, you can handle the response here
        // You may also want to parse the response as needed
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Err: ${e.toString()}');
    }
  }

  Future<void> addNotification(New notification) async {
    try {
      final url = Uri.parse('$_baseUrl$_endpoint/Add');
      final request = http.MultipartRequest('POST', url);

      request.fields['Id'] = notification.id.toString();
      request.fields['CreatedAt'] = notification.createdAt!.toIso8601String();
      request.fields['IsDeleted'] = notification.isDeleted.toString();
      request.fields['UserId'] = notification.userId.toString();
      request.fields['TotalRecordsCount'] =
          notification.totalRecordsCount.toString();
      request.fields['Text'] = notification.text ?? '';
      request.fields['Image'] = notification.image ?? '';
      request.fields['Name'] = notification.name ?? '';

      if (notification.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', notification.file!.path,
              contentType: http_parser.MediaType(
                  'image', 'jpeg')), // Set content type as needed
        );
      }
      final response = await request.send();
      if (response.statusCode == 200) {
        // Photo uploaded successfully, you can handle the response here
        // You may also want to parse the response as needed
      } else {
        // Handle errors here
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<List<New>> getAllNews() async {
    var url = "$_baseUrl$_endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);
    List<New> news = [];
    if (isValidResponse(response)) {
      return (jsonDecode(response.body) as List)
          .map((item) => New.fromJson(item))
          .toList();
    }
    throw Exception("Something is wrong");
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

  Future<List<New>> get({dynamic filter}) async {
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
            .map((item) => New.fromJson(item))
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
