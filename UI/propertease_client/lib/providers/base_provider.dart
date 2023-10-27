import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

import '../models/property.dart';
import '../models/search_result.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? _baseUrl;
  late String _endpoint;
  HttpClient client = HttpClient();
  IOClient? http;
  BaseProvider(String endpoint) {
    _endpoint = endpoint;
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://10.0.2.2:7137/api/");

    client.badCertificateCallback = (cert, host, port) => true;
    http = IOClient(client);
  }

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint";

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http!.get(uri, headers: headers);

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

  Future<T> updateAsync(int? id, T data) async {
    var url = "$_baseUrl$_endpoint/$id";
    var headers = createHeaders();
    var requestBody =
        jsonEncode(toJson(data)); // Make sure data has toJson() method

    var response = await http!.put(
      Uri.parse(url),
      headers: headers,
      body: requestBody,
    );

    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to update item");
    }
  }

  Future<T> addAsync(T data) async {
    var url = "$_baseUrl$_endpoint";
    var headers = createHeaders();
    var requestBody = jsonEncode(toJson(data));

    var response =
        await http!.post(Uri.parse(url), headers: headers, body: requestBody);
    print(response.statusCode);
    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    } else {
      // ignore: prefer_interpolation_to_compose_strings
      throw Exception("Failed to insert item");
    }
  }

  Future<void> deleteById(int? id) async {
    var url = "$_baseUrl$_endpoint/$id";
    final headers = createHeaders();

    final response = await http!.delete(Uri.parse(url), headers: headers);
    print(url);
    if (response.statusCode == 200) {
      // Successful deletion
      print("Property deleted successfully");
    } else if (response.statusCode == 404) {
      // Property not found, handle as needed
      throw Exception("Property not found");
    } else {
      // Handle other error cases
      throw Exception(
          "Failed to delete property. Status code: ${response.statusCode}");
    }
  }

  Future<SearchResult<T>> getFiltered({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint/GetFilteredData";
    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http!.get(uri, headers: headers);

    var result = SearchResult<T>();

    if (isValidResponse(response)) {
      List data = jsonDecode(response.body);
      result.count = data.length;

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

  Map<String, dynamic> toJson(T data) {
    throw UnimplementedError(
        "The 'toJson' method is not implemented for this provider.");
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
    // String username = Authorization.username ?? "";
    // String password = Authorization.password ?? "";

    // String basicAuth =
    //     "Basic ${base64Encode(utf8.encode('$username:$password'))}";
    var headers = {
      "Content-Type": "application/json",
      // "Authorization": basicAuth,
    };
    return headers;
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
