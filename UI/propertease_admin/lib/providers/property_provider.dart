import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/providers/base_provider.dart';

import '../models/property.dart';

class PropertyProvider extends BaseProvider<Property> {
  PropertyProvider() : super("Property");

  @override
  Property fromJson(data) => Property.fromJson(data);

  @override
  Map<String, dynamic> toJson(Property data) => data.toJson();

  Future<List<Property>> getRecommendations(int propertyId) async {
    final baseUrl = AppConfig.apiBase;
    final url = '${baseUrl}Property/$propertyId/Recommendations';
    final response = await http.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Property.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
