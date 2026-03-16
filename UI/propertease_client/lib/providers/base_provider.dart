import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

import '../config/app_config.dart';
import '../models/search_result.dart';
import '../utils/authorization.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String get baseUrl => AppConfig.apiBase;
  late String _endpoint;
  HttpClient client = HttpClient();
  IOClient? http;

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
    client.badCertificateCallback = (cert, host, port) => true;
    http = IOClient(client);
  }

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = '$baseUrl$_endpoint';
    if (filter != null) {
      url = '$url?${getQueryString(filter)}';
    }
    final response = await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final result = SearchResult<T>();
      final data = jsonDecode(response.body);
      // Support both array and paginated {result:[...], totalCount:N}
      final List items = data is List ? data : (data['result'] as List? ?? []);
      result.count = items.length;
      for (var item in items) {
        result.result.add(fromJson(item));
      }
      return result;
    }
    throw Exception('Something went wrong');
  }

  Future<SearchResult<T>> getFiltered({dynamic filter}) async {
    var url = '$baseUrl$_endpoint/GetFilteredData';
    if (filter != null) {
      url = '$url?${getQueryString(filter)}';
    }
    final response = await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final result = SearchResult<T>();
      final data = jsonDecode(response.body);
      // API returns PagedResult: { "items": [...], "totalCount": N }
      final List items = data is List
          ? data
          : (data['items'] as List? ?? data['result'] as List? ?? []);
      result.count = data is Map
          ? (data['totalCount'] as int? ?? items.length)
          : items.length;
      for (var item in items) {
        result.result.add(fromJson(item));
      }
      return result;
    }
    throw Exception('Something went wrong');
  }

  Future<T> getById(int id) async {
    final url = '$baseUrl$_endpoint/$id';
    final response = await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    }
    throw Exception('Not found');
  }

  Future<T> addAsync(T data) async {
    final url = '$baseUrl$_endpoint';
    final response = await http!.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode(toJson(data)),
    );
    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    }
    throw Exception(
        'Failed to insert. Status: ${response.statusCode}, Body: ${response.body}');
  }

  Future<T> updateAsync(int? id, T data) async {
    final url = '$baseUrl$_endpoint/$id';
    final response = await http!.put(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode(toJson(data)),
    );
    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update. Status: ${response.statusCode}');
  }

  Future<void> deleteById(int? id) async {
    final url = '$baseUrl$_endpoint/$id';
    final response =
        await http!.delete(Uri.parse(url), headers: createHeaders());
    if (response.statusCode == 404) throw Exception('Not found');
    if (response.statusCode >= 300) {
      throw Exception('Failed to delete. Status: ${response.statusCode}');
    }
  }

  T fromJson(data) => throw UnimplementedError('fromJson not implemented');
  Map<String, dynamic> toJson(T data) =>
      throw UnimplementedError('toJson not implemented');

  bool isValidResponse(Response response) {
    if (response.statusCode < 300) return true;
    if (response.statusCode == 401) throw Exception('Unauthorized');
    if (response.statusCode == 403) throw Exception('Forbidden');
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }

  Map<String, String> createHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (Authorization.token != null && Authorization.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${Authorization.token}';
    }
    return headers;
  }

  String getQueryString(Map params, {String prefix = '&'}) {
    String query = '';
    params.forEach((key, value) {
      if (value != null) {
        if (value is String || value is int || value is double || value is bool) {
          query += '$prefix$key=${Uri.encodeComponent(value.toString())}';
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
