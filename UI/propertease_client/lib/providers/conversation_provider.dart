import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:propertease_client/models/conversation.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:propertease_client/utils/authorization.dart';

import '../models/search_result.dart';

class ConversationProvider with ChangeNotifier {
  String get _baseUrl => AppConfig.apiBase;
  final String _endpoint = 'Conversation';
  late final IOClient http;

  ConversationProvider() {
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    http = IOClient(client);
  }

  Map<String, String> createHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (Authorization.token != null && Authorization.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${Authorization.token}';
    }
    return headers;
  }

  bool isValidResponse(Response response) {
    if (response.statusCode < 300) return true;
    if (response.statusCode == 401) throw Exception('Unauthorized');
    if (response.statusCode == 403) throw Exception('Forbidden');
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }

  Future<SearchResult<Conversation>> getByClient(int clientId) async {
    final url = '$_baseUrl$_endpoint/GetByClient/clientId/$clientId';
    final response =
        await http.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final List data = jsonDecode(response.body);
      final result = SearchResult<Conversation>();
      result.count = data.length;
      for (var item in data) {
        result.result.add(Conversation.fromJson(item as Map<String, dynamic>));
      }
      return result;
    }
    throw Exception('Failed to load conversations');
  }

  Future<Conversation> getLastByClient(int clientId) async {
    final url = '$_baseUrl$_endpoint/GetLastByClient/$clientId';
    final response =
        await http.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final data = jsonDecode(response.body);
      if (data != null) return Conversation.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('No conversation found');
  }

  Future<List<Conversation>> getByPropertyAndRenter(
      int propertyId, int renterId) async {
    final url =
        '$_baseUrl$_endpoint/GetByPropertyAndRenter?propertyId=$propertyId&renterId=$renterId';
    final response =
        await http.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<int> getUnreadCount(int recipientId) async {
    final url = '${_baseUrl}Message/UnreadCount/$recipientId';
    final response =
        await http.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      return jsonDecode(response.body) as int? ?? 0;
    }
    return 0;
  }

  Future<Conversation> addAsync(Conversation data) async {
    final url = '$_baseUrl$_endpoint';
    final response = await http.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode(data.toJson()),
    );
    if (isValidResponse(response)) {
      return Conversation.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(
        'Failed to create conversation. Status: ${response.statusCode}');
  }

  Future<void> deleteById(int? id) async {
    final url = '$_baseUrl$_endpoint/$id';
    final response =
        await http.delete(Uri.parse(url), headers: createHeaders());
    if (response.statusCode == 404) throw Exception('Not found');
    if (response.statusCode >= 300) {
      throw Exception('Failed to delete. Status: ${response.statusCode}');
    }
  }

  String getQueryString(Map params, {String prefix = '&'}) {
    String query = '';
    params.forEach((key, value) {
      if (value != null) {
        if (value is String || value is int || value is double || value is bool) {
          query += '$prefix$key=${Uri.encodeComponent(value.toString())}';
        } else if (value is DateTime) {
          query += '$prefix$key=${value.toIso8601String()}';
        }
      }
    });
    return query;
  }
}
