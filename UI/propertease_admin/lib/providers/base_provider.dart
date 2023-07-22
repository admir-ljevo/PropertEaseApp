import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/utils/authorization.dart';

import '../models/property.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? _baseUrl;
  late String _endpoint;

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://localhost:44340/api/");
  }

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint";

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    var result = SearchResult<T>();

    List data = jsonDecode(response.body);

    result.count = data.length;

    if (isValidResponse(response)) {
      for (var item in data) {
        result.result.add(fromJson(item));
      }

      return result;
    }
    throw Exception("Something is wrong");
  }

  Future<SearchResult<T>> getFiltered({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint/GetFilteredData";

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    var result = SearchResult<T>();

    List data = jsonDecode(response.body);

    result.count = data.length;

    if (isValidResponse(response)) {
      for (var item in data) {
        result.result.add(fromJson(item));
      }

      return result;
    }
    throw Exception("Something is wrong");
  }

  T fromJson(data) {
    throw Exception("Method not implemented");
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

  Map<String, String> createHeaders() {
    String username = Authorization.username ?? "";
    String password = Authorization.password ?? "";

    String basicAuth =
        "Basic ${base64Encode(utf8.encode('$username:$password'))}";
    var headers = {
      "Content-Type": "application/json",
      // "Authorization": basicAuth,
    };
    return headers;
  }

  String getQueryString(Map params,
      {String prefix: '&', bool inRecursion: false}) {
    String query = '';
    params.forEach((key, value) {
      if (inRecursion) {
        if (key is int) {
          key = '[$key]';
        } else if (value is List || value is Map) {
          key = '.$key';
        } else {
          key = '.$key';
        }
      }
      if (value is String || value is int || value is double || value is bool) {
        var encoded = value;
        if (value is String) {
          encoded = Uri.encodeComponent(value);
        }
        query += '$prefix$key=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$key=${(value as DateTime).toIso8601String()}';
      } else if (value is List || value is Map) {
        if (value is List) value = value.asMap();
        value.forEach((k, v) {
          query +=
              getQueryString({k: v}, prefix: '$prefix$key', inRecursion: true);
        });
      }
    });
    return query;
  }
}
