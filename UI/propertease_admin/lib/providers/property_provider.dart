import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/utils/authorization.dart';

import '../models/property.dart';

class PropertyProvider with ChangeNotifier {
  static String? _baseUrl;
  String _endpoint = "Property";

  PropertyProvider() {
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://localhost:44340/api/");
  }

  Future<SearchResult<Property>> getProperties() async {
    var url = "$_baseUrl$_endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    var result = SearchResult<Property>();

    List data = jsonDecode(response.body);

    result.count = data.length;

    if (isValidResponse(response)) {
      for (var item in data) {
        Property p = Property();
        p.id = item['id'];
        p.name = item['name'];
        result.result.add(p);
      }

      return result;
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
}
