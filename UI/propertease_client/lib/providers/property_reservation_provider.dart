import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_reservation.dart';
import 'base_provider.dart';
import 'package:propertease_client/utils/authorization.dart';

class ReservationSummary {
  final int id;
  final String? reservationNumber;
  final DateTime? dateOfOccupancyStart;
  final DateTime? dateOfOccupancyEnd;
  final double? totalPrice;
  final bool? isActive;
  final String? propertyName;

  const ReservationSummary({
    required this.id,
    this.reservationNumber,
    this.dateOfOccupancyStart,
    this.dateOfOccupancyEnd,
    this.totalPrice,
    this.isActive,
    this.propertyName,
  });

  factory ReservationSummary.fromJson(Map<String, dynamic> json) =>
      ReservationSummary(
        id: json['id'] ?? 0,
        reservationNumber: json['reservationNumber'],
        dateOfOccupancyStart: json['dateOfOccupancyStart'] != null
            ? DateTime.tryParse(json['dateOfOccupancyStart'])
            : null,
        dateOfOccupancyEnd: json['dateOfOccupancyEnd'] != null
            ? DateTime.tryParse(json['dateOfOccupancyEnd'])
            : null,
        totalPrice: (json['totalPrice'] as num?)?.toDouble(),
        isActive: json['isActive'],
        propertyName: json['propertyName'],
      );
}

class SummaryPage {
  final List<ReservationSummary> items;
  final int totalCount;
  const SummaryPage({required this.items, required this.totalCount});
}

class PropertyReservationProvider extends BaseProvider<PropertyReservation> {
  PropertyReservationProvider() : super("PropertyReservation");

  @override
  PropertyReservation fromJson(data) => PropertyReservation.fromJson(data);

  @override
  Map<String, dynamic> toJson(PropertyReservation data) => data.toJson();

  Future<SummaryPage> getClientSummaries(int clientId,
          {int page = 1, int pageSize = 10}) =>
      _fetchSummaries('client/$clientId/summary', page, pageSize);

  Future<SummaryPage> getRenterSummaries(int renterId,
          {int page = 1, int pageSize = 10}) =>
      _fetchSummaries('renter/$renterId/summary', page, pageSize);

  Future<SummaryPage> _fetchSummaries(
      String path, int page, int pageSize) async {
    final url =
        '${BaseProvider.baseUrl}PropertyReservation/$path?page=$page&pageSize=$pageSize';
    final response = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Authorization.token}',
    });
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (body['items'] as List)
          .map((e) => ReservationSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      return SummaryPage(
          items: items, totalCount: body['totalCount'] as int? ?? 0);
    }
    throw Exception('Failed to load summaries (${response.statusCode})');
  }
}
