import 'package:http/http.dart' as http;
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/payment.dart';
import 'base_provider.dart';

class PaymentProvider extends BaseProvider<Payment> {
  PaymentProvider() : super('Payment');

  @override
  Payment fromJson(data) => Payment.fromJson(data);

  @override
  Map<String, dynamic> toJson(Payment data) => {};

  Future<void> refundReservation(int reservationId,
      {bool isClient = false, String? reason}) async {
    var url =
        '${AppConfig.apiBase}Payment/RefundReservation/$reservationId?isClient=$isClient';
    if (reason != null && reason.isNotEmpty) {
      url += '&reason=${Uri.encodeQueryComponent(reason)}';
    }
    final response =
        await http.post(Uri.parse(url), headers: createHeaders());
    if (!isValidResponse(response)) {
      throw Exception(
          response.body.isNotEmpty ? response.body : 'Refund failed');
    }
  }
}
