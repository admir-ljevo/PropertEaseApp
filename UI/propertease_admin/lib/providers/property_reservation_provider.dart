import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/providers/base_provider.dart';
import 'package:propertease_admin/utils/authorization.dart';

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
  Map<String, dynamic> toJson(PropertyReservation data) => {
        'id': data.id,
        'propertyId': data.propertyId,
        'clientId': data.clientId,
        'numberOfGuests': data.numberOfGuests,
        'dateOfOccupancyStart': data.dateOfOccupancyStart?.toIso8601String(),
        'dateOfOccupancyEnd': data.dateOfOccupancyEnd?.toIso8601String(),
        'numberOfDays': data.numberOfDays,
        'numberOfMonths': data.numberOfMonths,
        'totalPrice': data.totalPrice,
        'isMonthly': data.isMonthly,
        'isDaily': data.isDaily,
        'isActive': data.isActive,
        'reservationNumber': data.reservationNumber,
        'description': data.description,
        'isDeleted': data.isDeleted,
        'createdAt': data.createdAt?.toIso8601String(),
      };

  Future<void> confirmReservation(int id) async {
    final url = Uri.parse('${AppConfig.apiBase}PropertyReservation/$id/confirm');
    final response = await http.post(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Authorization.token}',
    });
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Potvrda neuspješna: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> cancelReservation(PropertyReservation r, {String? reason}) async {
    final url = Uri.parse('${AppConfig.apiBase}PropertyReservation/${r.id}');
    final body = jsonEncode({
      'id': r.id,
      'propertyId': r.propertyId,
      'reservationNumber': r.reservationNumber ?? '',
      'description': r.description,
      'renterId': r.renterId ?? 0,
      'clientId': r.clientId ?? 0,
      'numberOfGuests': r.numberOfGuests ?? 1,
      'dateOfOccupancyStart': r.dateOfOccupancyStart?.toIso8601String(),
      'dateOfOccupancyEnd': r.dateOfOccupancyEnd?.toIso8601String(),
      'numberOfDays': r.numberOfDays ?? 0,
      'numberOfMonths': r.numberOfMonths ?? 0,
      'totalPrice': r.totalPrice ?? 0,
      'isMonthly': r.isMonthly ?? false,
      'isDaily': r.isDaily ?? false,
      'status': 3,
      'cancellationReason': reason ?? 'Odbijeno od strane iznajmljivača',
    });
    final response = await http.put(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Authorization.token}',
        },
        body: body);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Otkazivanje neuspješno: ${response.statusCode} ${response.body}');
    }
  }

  Future<SummaryPage> getClientSummaries(int clientId,
      {int page = 1, int pageSize = 10}) =>
      _fetchSummaries('client/$clientId/summary', page, pageSize);

  Future<SummaryPage> getRenterSummaries(int renterId,
      {int page = 1, int pageSize = 10}) =>
      _fetchSummaries('renter/$renterId/summary', page, pageSize);

  Future<SummaryPage> _fetchSummaries(
      String path, int page, int pageSize) async {
    final url =
        '${AppConfig.apiBase}PropertyReservation/$path?page=$page&pageSize=$pageSize';
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
