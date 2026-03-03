import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

import '../models/new.dart';

class NotificationProvider with ChangeNotifier {
  static String? _baseUrl;
  HttpClient client = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      return true;
    };
  IOClient? http;
  String _endpoint = 'Notification';

  NotificationProvider() {
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://10.0.2.2:7137/api/");
    client.badCertificateCallback = (cert, host, port) => true;
    http = IOClient(client);
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

  Future<List<New>> getAllNews() async {
    var url = "$_baseUrl$_endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http!.get(uri, headers: headers);
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
    var response = await http!.get(uri, headers: headers);
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
