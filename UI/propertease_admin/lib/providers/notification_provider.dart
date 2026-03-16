import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/new.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/utils/authorization.dart';

class NotificationProvider with ChangeNotifier {
  static String get _baseUrl => AppConfig.apiBase;
  String _endpoint = 'Notification';

  NotificationProvider();

  Map<String, String> createHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = Authorization.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
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

      final token = Authorization.token;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['Id'] = notification.id.toString();
      request.fields['UserId'] = notification.userId.toString();
      request.fields['Text'] = notification.text ?? '';
      request.fields['Image'] = notification.image ?? '';
      request.fields['Name'] = notification.name ?? '';

      if (notification.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('File', notification.file!.path,
              contentType: http_parser.MediaType('image', 'jpeg')),
        );
      }

      final response = await request.send();
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        print('updateNotification error ${response.statusCode}: $body');
      }
    } catch (e) {
      print('Err: ${e.toString()}');
    }
  }

  Future<void> addNotification(New notification) async {
    try {
      final url = Uri.parse('$_baseUrl$_endpoint/Add');
      final request = http.MultipartRequest('POST', url);

      final token = Authorization.token;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['UserId'] = notification.userId.toString();
      request.fields['Text'] = notification.text ?? '';
      request.fields['Name'] = notification.name ?? '';

      if (notification.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('File', notification.file!.path,
              contentType: http_parser.MediaType('image', 'jpeg')),
        );
      }

      final response = await request.send();
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        print('addNotification error ${response.statusCode}: $body');
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

  Future<SearchResult<New>> get({dynamic filter}) async {
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
        final result = SearchResult<New>();
        result.totalCount = (decoded['totalCount'] as int?) ?? 0;
        result.count = items.length;
        result.result = items.map((item) => New.fromJson(item)).toList();
        return result;
      } else {
        throw Exception("Not valid response");
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
