import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/providers/base_provider.dart';

import '../models/property.dart';

class UpcomingReservationsException implements Exception {
  final int count;
  UpcomingReservationsException(this.count);
}

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

  /// Returns 0 on success, or the upcoming reservation count on 409.
  @override
  Future<void> deleteById(int? id) async {
    final baseUrl = AppConfig.apiBase;
    final response = await http.delete(
      Uri.parse('${baseUrl}Property/$id'),
      headers: createHeaders(),
    );
    if (response.statusCode == 200) return;
    if (response.statusCode == 409) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final count = (body['upcomingCount'] as int?) ?? 0;
      throw UpcomingReservationsException(count);
    }
    throw Exception('Failed to delete property. Status: ${response.statusCode}');
  }

  Future<void> forceDeleteById(int id) async {
    final baseUrl = AppConfig.apiBase;
    final response = await http.delete(
      Uri.parse('${baseUrl}Property/$id/force'),
      headers: createHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Force delete failed. Status: ${response.statusCode}');
    }
  }

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
