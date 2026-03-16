import 'dart:convert';

import '../models/property.dart';
import 'base_provider.dart';

class PropertyProvider extends BaseProvider<Property> {
  PropertyProvider() : super("Property") {}

  @override
  Property fromJson(data) {
    return Property.fromJson(data);
  }

  @override
  Map<String, dynamic> toJson(Property data) {
    return data.toJson();
  }

  Future<List<Property>> getRecommendations(int propertyId) async {
    final url = '${BaseProvider.baseUrl}Property/$propertyId/Recommendations';
    final response = await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Property.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
