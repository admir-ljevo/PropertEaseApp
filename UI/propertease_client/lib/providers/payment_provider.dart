import 'dart:convert';
import 'package:propertease_client/models/property_reservation.dart';
import 'base_provider.dart';

class PaymentProvider extends BaseProvider<PropertyReservation> {
  PaymentProvider() : super("Payment");

  @override
  PropertyReservation fromJson(data) => PropertyReservation.fromJson(data);

  @override
  Map<String, dynamic> toJson(PropertyReservation data) => data.toJson();

  Future<Map<String, dynamic>> getPayPalConfig() async {
    final url = '${BaseProvider.baseUrl}Payment/Config';
    final response = await http!.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load PayPal config');
  }

  /// Creates a PayPal payment server-side and returns [paymentId] + [approvalUrl].
  /// The client must open [approvalUrl] in a WebView and intercept the redirect.
  Future<Map<String, dynamic>> createPayPalOrder(int reservationId) async {
    final url =
        '${BaseProvider.baseUrl}Payment/CreatePayPalOrder?reservationId=$reservationId';
    final response =
        await http!.post(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
        'Failed to create PayPal order: ${response.statusCode} ${response.body}');
  }

  Future<PropertyReservation> completeReservation(
      Map<String, dynamic> data) async {
    final url = '${BaseProvider.baseUrl}Payment/CompleteReservation';
    final response = await http!.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode(data),
    );
    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    }
    throw Exception(
        'Failed to complete reservation: ${response.statusCode} ${response.body}');
  }

  /// Pays for an already-confirmed reservation (Pending → paid).
  Future<PropertyReservation> payForReservation(Map<String, dynamic> data) async {
    final url = '${BaseProvider.baseUrl}Payment/PayForReservation';
    final response = await http!.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode(data),
    );
    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    }
    throw Exception(
        'Plaćanje neuspješno: ${response.statusCode} ${response.body}');
  }

  /// Cancels a reservation and refunds the PayPal payment.
  /// [isClient] = true enforces the 7-day rule server-side.
  Future<void> refundReservation(int reservationId,
      {bool isClient = false}) async {
    final url =
        '${BaseProvider.baseUrl}Payment/RefundReservation/$reservationId?isClient=$isClient';
    final response =
        await http!.post(Uri.parse(url), headers: createHeaders());
    if (!isValidResponse(response)) {
      final body = response.body;
      throw Exception(body.isNotEmpty ? body : 'Refund failed');
    }
  }
}
