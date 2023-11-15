import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:propertease_admin/models/message.dart';

import '../models/property.dart';
import '../models/search_result.dart';

class MessageProvider with ChangeNotifier {
  static String? _baseUrl;
  late String _endpoint;
  HttpClient client = HttpClient();
  IOClient? http;
  MessageProvider() {
    _endpoint = "Message";
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://localhost:7137/api/");

    client.badCertificateCallback = (cert, host, port) => true;
    http = IOClient(client);
  }

  Future<SearchResult<Message>> get({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint";

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http!.get(uri, headers: headers);

    var result = SearchResult<Message>();

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

  Future<SearchResult<Message>> getByConversationId(int conversationId) async {
    var url = "$_baseUrl$_endpoint/GetByConversationId/$conversationId";

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http!.get(uri, headers: headers);

    var result = SearchResult<Message>();

    List data = jsonDecode(response.body);
    print(url);
    result.count = data.length;

    if (isValidResponse(response)) {
      for (var item in data) {
        result.result.add(Message.fromJson(item));
      }
      print(response.statusCode);
      return result;
    }
    throw Exception("Something is wrong");
  }

  Future<Message> updateAsync(int? id, Message data) async {
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

  Future<Message> addMessage(Message data) async {
    var url = "$_baseUrl$_endpoint/AddMessage";
    var headers = createHeaders();
    var requestBody = jsonEncode(toJson(data));

    var response =
        await http!.post(Uri.parse(url), headers: headers, body: requestBody);
    if (isValidResponse(response)) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      final responseStatusCode = response.statusCode;
      final responseBody = response.body;
      final errorMessage =
          "Failed to insert item. Status Code: $responseStatusCode, Response Body: $responseBody";
      print(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<Message> addAsync(Message data) async {
    var url = "$_baseUrl$_endpoint";
    var headers = createHeaders();
    var requestBody = jsonEncode(toJson(data));

    var response =
        await http!.post(Uri.parse(url), headers: headers, body: requestBody);
    if (isValidResponse(response)) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      final responseStatusCode = response.statusCode;
      final responseBody = response.body;
      final errorMessage =
          "Failed to insert item. Status Code: $responseStatusCode, Response Body: $responseBody";
      print(errorMessage);
      throw Exception(errorMessage);
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

  Future<SearchResult<Message>> getFiltered({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint/GetFilteredData";

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http!.get(uri, headers: headers);

    var result = SearchResult<Message>();

    List data = jsonDecode(response.body);

    result.count = data.length;
    print(url);
    if (isValidResponse(response)) {
      for (var item in data) {
        result.result.add(fromJson(item));
      }

      return result;
    }
    throw Exception("Something is wrong");
  }

  Message fromJson(data) {
    throw Exception("Method not implemented");
  }

  Map<String, dynamic> toJson(Message data) {
    return data.toJson();
  }

  bool isValidResponse(Response response) {
    if (response.statusCode < 299) {
      return true;
    }
    if (response.statusCode == 401) {
      throw Exception("Wrong credentials");
    }
    if (response.statusCode == 500) {
      throw Exception("Something else is wrong");
    }
    throw Exception("runje");
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
