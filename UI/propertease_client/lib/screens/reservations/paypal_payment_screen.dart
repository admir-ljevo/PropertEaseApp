import 'package:flutter/material.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:provider/provider.dart';
import '../../models/property_reservation.dart';
import '../../providers/payment_provider.dart';

class PayPalScreen extends StatefulWidget {
  final double totalPrice;
  final Map<String, dynamic> reservationData;
  final void Function(PropertyReservation reservation)? onReservationCreated;
  final void Function(String error)? onReservationError;
  final VoidCallback? onCancelled;

  const PayPalScreen({
    super.key,
    required this.totalPrice,
    required this.reservationData,
    this.onReservationCreated,
    this.onReservationError,
    this.onCancelled,
  });

  @override
  State<PayPalScreen> createState() => _PayPalScreenState();
}

class _PayPalScreenState extends State<PayPalScreen> {
  String? _clientId;
  String? _secretKey;
  bool _loadingConfig = true;
  bool _processingPayment = false;
  String? _error;
  // Captured early while context is valid — PayPalScreen is replaced (not
  // pushed) by CompletePayment, so context is deactivated before onSuccess fires.
  late PaymentProvider _paymentProvider;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      _paymentProvider = context.read<PaymentProvider>();
      final config = await _paymentProvider.getPayPalConfig();
      if (!mounted) return;
      setState(() {
        _clientId = config['clientId'] as String?;
        _secretKey = config['secretKey'] as String?;
        _loadingConfig = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingConfig = false;
      });
    }
  }

  // Synchronous — flutter_paypal does NOT await onSuccess callbacks and
  // may auto-pop this route before the callback returns. We must NOT guard
  // on `mounted` here, because the route may already be gone by the time
  // flutter_paypal fires onSuccess. All UI work is done via callbacks that
  // close over the still-live reservation_add_screen context.
  void _onPaymentSuccess(Map params) {
    debugPrint('[PayPal] onSuccess fired. params=$params');
    if (_processingPayment) {
      debugPrint('[PayPal] already processing, ignoring');
      return;
    }
    _processingPayment = true;
    _completeReservation(params, _paymentProvider);
  }

  Future<void> _completeReservation(Map params, PaymentProvider provider) async {
    try {
      debugPrint('[PayPal] calling backend CompleteReservation...');
      final result = await provider.completeReservation({
        ...widget.reservationData,
        "payPalPaymentId": params["paymentId"],
        // PayPal URL param is "PayerID" (capital D)
        "payPalPayerId": params["PayerID"] ?? params["payerID"] ?? "",
        "amount": widget.totalPrice,
      });
      debugPrint('[PayPal] reservation created, id=${result.id}');
      // Fire the caller's callback — its context is still mounted.
      widget.onReservationCreated?.call(result);
    } catch (e) {
      debugPrint('[PayPal] ERROR: $e');
      // Fire the caller's error callback so the error is visible even when
      // this screen is already unmounted.
      widget.onReservationError?.call(e.toString());
      if (mounted) {
        setState(() => _processingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create reservation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingConfig) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _clientId == null || _secretKey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(child: Text(_error ?? 'PayPal configuration unavailable')),
      );
    }

    final priceStr = widget.totalPrice.toStringAsFixed(2);

    return Stack(
      children: [
        UsePaypal(
          sandboxMode: true,
          clientId: _clientId!,
          secretKey: _secretKey!,
          returnURL: "https://success.snippetcoder.com",
          cancelURL: "https://cancel.snippetcoder.com",
          transactions: [
            {
              "amount": {
                "total": priceStr,
                "currency": "USD",
                "details": {
                  "subtotal": priceStr,
                  "shipping": "0",
                  "shipping_discount": 0,
                },
              },
              "description": "Property reservation payment",
              "item_list": {
                "items": [
                  {
                    "name": "Property Reservation",
                    "quantity": 1,
                    "price": priceStr,
                    "currency": "USD",
                  }
                ],
              },
            }
          ],
          note: "Contact us for any questions on your order.",
          onSuccess: _onPaymentSuccess,
          onError: (error) {
            debugPrint('[PayPal] onError: $error');
            widget.onReservationError?.call('PayPal error: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          onCancel: (params) {
            widget.onCancelled?.call();
            if (mounted) Navigator.of(context).pop(false);
          },
        ),
        if (_processingPayment)
          const Scaffold(
            backgroundColor: Colors.black54,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Creating your reservation...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
