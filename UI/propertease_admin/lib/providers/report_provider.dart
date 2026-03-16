import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/utils/authorization.dart';

class ReportProvider {
  static String get _baseUrl => AppConfig.apiBase;

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = Authorization.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// [type] is one of: reservations, revenue, payments
  Future<Uint8List> downloadReport(
    String type, {
    int? ownerId,
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{};
    if (ownerId != null) params['ownerId'] = ownerId.toString();
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();

    final uri = Uri.parse('${_baseUrl}Report/$type')
        .replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Report download failed (${response.statusCode})');
  }
}
