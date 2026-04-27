import 'dart:convert';

import 'package:propertease_client/models/message.dart';
import 'package:propertease_client/providers/base_provider.dart';

import '../models/search_result.dart';

class MessageProvider extends BaseProvider<Message> {
  MessageProvider() : super('Message');

  @override
  Message fromJson(data) => Message.fromJson(data as Map<String, dynamic>);

  @override
  Map<String, dynamic> toJson(Message data) => data.toJson();

  Future<SearchResult<Message>> getByConversationId(
    int conversationId, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final url =
        '${BaseProvider.baseUrl}Message/GetByConversationId/$conversationId?page=$page&pageSize=$pageSize';
    final response = await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final List data = jsonDecode(response.body);
      final result = SearchResult<Message>();
      result.count = data.length;
      for (var item in data) {
        result.result.add(fromJson(item));
      }
      return result;
    }
    throw Exception('Failed to load messages');
  }

  Future<void> markAsRead(int conversationId, int recipientId) async {
    final url =
        '${BaseProvider.baseUrl}Message/MarkAsRead/$conversationId?recipientId=$recipientId';
    await http!.put(Uri.parse(url), headers: createHeaders());
  }

  Future<Message> addMessage(Message data) async {
    final url = '${BaseProvider.baseUrl}Message/AddMessage';
    final response = await http!.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode(toJson(data)),
    );
    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to send message. Status: ${response.statusCode}');
  }
}
