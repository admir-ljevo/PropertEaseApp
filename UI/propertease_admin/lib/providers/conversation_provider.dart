import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/models/conversation.dart';
import 'package:propertease_admin/utils/authorization.dart';

import '../models/search_result.dart';

class ConversationProvider with ChangeNotifier {
  static String get _baseUrl => AppConfig.apiBase;
  late String _endpoint;
  HttpClient client = HttpClient();
  IOClient? http;

  ConversationProvider() {
    _endpoint = "Conversation";

    client.badCertificateCallback = (cert, host, port) => true;
    http = IOClient(client);
  }

  Map<String, String> createHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = Authorization.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  bool isValidResponse(Response response) {
    if (response.statusCode < 299) return true;
    if (response.statusCode == 401) throw Exception("Wrong credentials");
    if (response.statusCode == 500) throw Exception("Server error");
    throw Exception("Request failed (${response.statusCode})");
  }

  Conversation fromJson(dynamic data) =>
      Conversation.fromJson(data as Map<String, dynamic>);

  Map<String, dynamic> toJson(Conversation data) => data.toJson();

  // ── All property conversations (admin overview) ───────────────────────────

  Future<SearchResult<Conversation>> get({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint";
    if (filter != null) {
      url = "$url?${getQueryString(filter)}";
    }
    final response =
        await http!.get(Uri.parse(url), headers: createHeaders());
    final result = SearchResult<Conversation>();
    final List data = jsonDecode(response.body);
    result.count = data.length;
    if (isValidResponse(response)) {
      for (var item in data) result.result.add(fromJson(item));
      return result;
    }
    throw Exception("Something is wrong");
  }

  // ── Property conversations for a renter ───────────────────────────────────

  Future<SearchResult<Conversation>> getByPropertyAndRenter(
      int? propertyId, int renterId) async {
    final queryParams = <String, dynamic>{
      'renterId': renterId,
    };
    if (propertyId != null) queryParams['propertyId'] = propertyId;
    final queryString = getQueryString(queryParams);
    final url =
        "$_baseUrl$_endpoint/GetByPropertyAndRenter?$queryString";
    final response =
        await http!.get(Uri.parse(url), headers: createHeaders());
    final result = SearchResult<Conversation>();
    final List data = jsonDecode(response.body);
    result.count = data.length;
    if (isValidResponse(response)) {
      for (var item in data) result.result.add(fromJson(item));
      return result;
    }
    throw Exception("Failed to fetch property conversations");
  }

  // ── Admin conversations (no property attached) ────────────────────────────

  Future<SearchResult<Conversation>> getAdminConversations(int userId) async {
    final url = "$_baseUrl$_endpoint/GetAdminConversations/$userId";
    final response =
        await http!.get(Uri.parse(url), headers: createHeaders());
    final result = SearchResult<Conversation>();
    final List data = jsonDecode(response.body);
    result.count = data.length;
    if (isValidResponse(response)) {
      for (var item in data) result.result.add(fromJson(item));
      return result;
    }
    throw Exception("Failed to fetch admin conversations");
  }

  // ── List of admin users (to start new admin conversation) ─────────────────

  Future<List<ApplicationUser>> getAdmins() async {
    final url = "$_baseUrl$_endpoint/GetAdmins";
    final response =
        await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => ApplicationUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Failed to fetch admins");
  }

  // ── Client inbox ───────────────────────────────────────────────────────────

  Future<SearchResult<Conversation>> getByClient(int clientId) async {
    final url = "$_baseUrl$_endpoint/GetByClient/clientId/$clientId";
    final response =
        await http!.get(Uri.parse(url), headers: createHeaders());
    final result = SearchResult<Conversation>();
    final List data = jsonDecode(response.body);
    result.count = data.length;
    if (isValidResponse(response)) {
      for (var item in data) result.result.add(fromJson(item));
      return result;
    }
    throw Exception("Failed to fetch client conversations");
  }

  // ── Unread count (uses Message endpoint) ──────────────────────────────────

  Future<int> getUnreadCount(int recipientId) async {
    final url = "$_baseUrl" "Message/UnreadCount/$recipientId";
    final response =
        await http!.get(Uri.parse(url), headers: createHeaders());
    if (response.statusCode < 299) {
      return jsonDecode(response.body) as int;
    }
    return 0;
  }

  // ── Mark conversation messages as read ────────────────────────────────────

  Future<void> markAsRead(int conversationId, int recipientId) async {
    final url = "$_baseUrl" "Message/MarkAsRead/$conversationId?recipientId=$recipientId";
    await http!.put(Uri.parse(url), headers: createHeaders());
  }

  // ── CRUD helpers ───────────────────────────────────────────────────────────

  Future<Conversation> addAsync(Conversation data) async {
    final body = {
      ...toJson(data),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    final response = await http!.post(
      Uri.parse("$_baseUrl$_endpoint"),
      headers: createHeaders(),
      body: jsonEncode(body),
    );
    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    }
    throw Exception(
        "Failed to insert item (${response.statusCode}): ${response.body}");
  }

  Future<void> deleteById(int? id) async {
    final response = await http!.delete(
        Uri.parse("$_baseUrl$_endpoint/$id"),
        headers: createHeaders());
    if (response.statusCode != 200) {
      throw Exception("Failed to delete (${response.statusCode})");
    }
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
