import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:propertease_client/models/message.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:propertease_client/utils/authorization.dart';

import '../models/search_result.dart';

class MessageProvider with ChangeNotifier {
  String get _baseUrl => AppConfig.apiBase;
  final String _endpoint = 'Message';
  late final IOClient http;

  MessageProvider() {
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

  Future<SearchResult<Message>> getByConversationId(int conversationId) async {
    final url = '$_baseUrl$_endpoint/GetByConversationId/$conversationId';
    final response =
        await http.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final List data = jsonDecode(response.body);
      final result = SearchResult<Message>();
      result.count = data.length;
      for (var item in data) {
        result.result.add(Message.fromJson(item as Map<String, dynamic>));
      }
      return result;
    }
    throw Exception('Failed to load messages');
  }

  Future<void> markAsRead(int conversationId, int recipientId) async {
    final url = '${_baseUrl}${_endpoint}/MarkAsRead/$conversationId?recipientId=$recipientId';
    await http.put(Uri.parse(url), headers: createHeaders());
  }

  Future<Message> addMessage(Message data) async {
    final url = '$_baseUrl$_endpoint/AddMessage';
    final response = await http.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode(data.toJson()),
    );
    if (isValidResponse(response)) {
      return Message.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to send message. Status: ${response.statusCode}');
  }
}
