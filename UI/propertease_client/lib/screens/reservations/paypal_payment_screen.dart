import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:propertease_client/models/property_reservation.dart';
import 'package:propertease_client/providers/payment_provider.dart';

const _returnUrl = 'https://propertease.app/payment/success';
const _cancelUrl  = 'https://propertease.app/payment/cancel';

class PayPalScreen extends StatefulWidget {
  final double totalPrice;
  final Map<String, dynamic> reservationData;
  final void Function(PropertyReservation reservation)? onReservationCreated;
  final void Function(String error)? onReservationError;
  final VoidCallback? onCancelled;

  /// When set, pays for an existing confirmed reservation instead of creating a new one.
  final int? existingReservationId;

  const PayPalScreen({
    super.key,
    this.totalPrice = 0,
    required this.reservationData,
    this.onReservationCreated,
    this.onReservationError,
    this.onCancelled,
    this.existingReservationId,
  });

  @override
  State<PayPalScreen> createState() => _PayPalScreenState();
}

class _PayPalScreenState extends State<PayPalScreen> {
  WebViewController? _webController;
  bool _loadingOrder   = true;
  bool _processingPayment = false;
  String? _error;
  late PaymentProvider _paymentProvider;

  @override
  void initState() {
    super.initState();
    _paymentProvider = context.read<PaymentProvider>();
    _createOrder();
  }

  Future<void> _createOrder() async {
    try {
      if (widget.existingReservationId == null) throw Exception('Reservation ID required');
      final order = await _paymentProvider.createPayPalOrder(widget.existingReservationId!);
      final approvalUrl = order['approvalUrl'] as String?;
      if (approvalUrl == null) throw Exception('No approval URL returned');

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: _handleNavigation,
        ))
        ..loadRequest(Uri.parse(approvalUrl));

      if (!mounted) return;
      setState(() {
        _webController  = controller;
        _loadingOrder   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error      = e.toString();
        _loadingOrder = false;
      });
    }
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final url = request.url;

    if (url.startsWith(_cancelUrl)) {
      widget.onCancelled?.call();
      if (mounted) Navigator.of(context).pop(false);
      return NavigationDecision.prevent;
    }

    if (url.startsWith(_returnUrl)) {
      final uri      = Uri.parse(url);
      final paymentId = uri.queryParameters['paymentId'];
      final payerId   = uri.queryParameters['PayerID'];

      if (paymentId == null || payerId == null) {
        widget.onReservationError?.call('PayPal redirect missing paymentId or PayerID');
        if (mounted) Navigator.of(context).pop(false);
        return NavigationDecision.prevent;
      }

      _completeReservation(paymentId, payerId);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _completeReservation(String paymentId, String payerId) async {
    if (_processingPayment) return;
    if (mounted) setState(() => _processingPayment = true);

    try {
      final PropertyReservation result;
      if (widget.existingReservationId != null) {
        result = await _paymentProvider.payForReservation({
          'reservationId':  widget.existingReservationId,
          'payPalPaymentId': paymentId,
          'payPalPayerId':   payerId,
          'amount':          widget.totalPrice,
        });
      } else {
        result = await _paymentProvider.completeReservation({
          ...widget.reservationData,
          'payPalPaymentId': paymentId,
          'payPalPayerId':   payerId,
          'amount':          widget.totalPrice,
        });
      }
      widget.onReservationCreated?.call(result);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      widget.onReservationError?.call(e.toString());
      if (mounted) {
        setState(() => _processingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingOrder) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _webController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(child: Text(_error ?? 'PayPal configuration unavailable')),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('PayPal Payment'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                widget.onCancelled?.call();
                Navigator.of(context).pop(false);
              },
            ),
          ),
          body: WebViewWidget(controller: _webController!),
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
