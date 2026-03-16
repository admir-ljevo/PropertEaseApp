import 'package:http/http.dart' as http;
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'base_provider.dart';

class PaymentProvider extends BaseProvider<PropertyReservation> {
  PaymentProvider() : super('Payment');

  @override
  PropertyReservation fromJson(data) => PropertyReservation.fromJson(data);

  @override
  Map<String, dynamic> toJson(PropertyReservation data) => data.toJson();

  /// Cancels a reservation and refunds the PayPal payment.
  /// [isClient] = true enforces the 7-day rule server-side.
  Future<void> refundReservation(int reservationId,
      {bool isClient = false}) async {
    final url =
        '${AppConfig.apiBase}Payment/RefundReservation/$reservationId?isClient=$isClient';
    final response =
        await http.post(Uri.parse(url), headers: createHeaders());
    if (!isValidResponse(response)) {
      throw Exception(
          response.body.isNotEmpty ? response.body : 'Refund failed');
    }
  }
}
