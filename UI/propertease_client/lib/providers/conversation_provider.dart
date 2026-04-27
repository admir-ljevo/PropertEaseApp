import 'dart:convert';

import 'package:propertease_client/models/conversation.dart';
import 'package:propertease_client/providers/base_provider.dart';

import '../models/search_result.dart';

class ConversationProvider extends BaseProvider<Conversation> {
  ConversationProvider() : super('Conversation');

  @override
  Conversation fromJson(data) =>
      Conversation.fromJson(data as Map<String, dynamic>);

  @override
  Map<String, dynamic> toJson(Conversation data) => data.toJson();

  Future<SearchResult<Conversation>> getByClient(int clientId) async {
    final url =
        '${BaseProvider.baseUrl}Conversation/GetByClient/clientId/$clientId';
    final response = await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final List data = jsonDecode(response.body);
      final result = SearchResult<Conversation>();
      result.count = data.length;
      for (var item in data) {
        result.result.add(fromJson(item));
      }
      return result;
    }
    throw Exception('Failed to load conversations');
  }

  Future<Conversation> getLastByClient(int clientId) async {
    final url =
        '${BaseProvider.baseUrl}Conversation/GetLastByClient/$clientId';
    final response = await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final data = jsonDecode(response.body);
      if (data != null) return fromJson(data);
    }
    throw Exception('No conversation found');
  }

  Future<List<Conversation>> getByPropertyAndRenter(
      int propertyId, int renterId) async {
    final url =
        '${BaseProvider.baseUrl}Conversation/GetByPropertyAndRenter?propertyId=$propertyId&renterId=$renterId';
    final response = await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final List data = jsonDecode(response.body);
      return data.map((e) => fromJson(e)).toList();
    }
    return [];
  }

  Future<int> getUnreadCount(int recipientId) async {
    final url = '${BaseProvider.baseUrl}Message/UnreadCount/$recipientId';
    final response = await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      return jsonDecode(response.body) as int? ?? 0;
    }
    return 0;
  }
}
