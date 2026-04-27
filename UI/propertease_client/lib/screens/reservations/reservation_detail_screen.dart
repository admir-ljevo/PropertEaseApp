import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:provider/provider.dart';

import 'package:propertease_client/models/property_reservation.dart';
import 'package:propertease_client/models/user_rating.dart';
import 'package:propertease_client/providers/payment_provider.dart';
import 'package:propertease_client/providers/property_reservation_provider.dart';
import 'package:propertease_client/providers/user_rating_provider.dart';
import 'package:propertease_client/utils/authorization.dart';
import 'package:propertease_client/utils/reservation_status.dart';
import 'package:propertease_client/screens/property/reviews/review_list.dart';
import 'package:propertease_client/screens/users/renter_profile_screen.dart';
import 'paypal_payment_screen.dart';

class ReservationDetailsScreen extends StatefulWidget {
  final int reservationId;
  const ReservationDetailsScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailsScreen> {
  PropertyReservation? _reservation;
  bool _loading = true;
  bool _cancelling = false;
  bool _paying = false;
  String? _error;
  UserRating? _existingUserRating;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _canCancel {
    final r = _reservation;
    if (r == null || r.status != 1) return false;
    final checkIn = r.dateOfOccupancyStart;
    if (checkIn == null) return false;
    return checkIn.difference(DateTime.now()).inDays >= 7;
  }

  bool get _canPay {
    final r = _reservation;
    if (r == null) return false;
    return r.status == 1 && !(r.isPaid ?? false);
  }

  bool get _isPending => _reservation?.status == 0;

  Future<void> _payReservation() async {
    final r = _reservation!;
    setState(() => _paying = true);
    try {
      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PayPalScreen(
            totalPrice: r.totalPrice ?? 0,
            reservationData: const {},
            existingReservationId: r.id,
            onReservationCreated: (_) {},
            onReservationError: (err) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Plaćanje neuspješno: $err'),
                  backgroundColor: Colors.red,
                ));
              }
            },
          ),
        ),
      );
      if (paid == true && mounted) _load();
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _cancelPending() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Otkazivanje zahtjeva'),
        content: const Text('Da li ste sigurni da želite povući zahtjev za rezervaciju?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Povuci zahtjev'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<PropertyReservationProvider>();
    setState(() => _cancelling = true);
    try {
      await provider.cancelReservation(_reservation!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zahtjev povučen.'), backgroundColor: Colors.green),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _cancelReservation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Otkazivanje rezervacije'),
        content: const Text(
            'Da li ste sigurni da želite otkazati rezervaciju? Izvršit će se povrat novca na vaš PayPal račun.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Otkaži rezervaciju'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await context
          .read<PaymentProvider>()
          .refundReservation(_reservation!.id!, isClient: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rezervacija otkazana. Refund je u obradi.'),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _load() async {
    try {
      final r = await context
          .read<PropertyReservationProvider>()
          .getById(widget.reservationId);
      setState(() {
        _reservation = r;
        _loading = false;
      });
      if (r.status == 2 && r.renterId != null) {
        _loadExistingUserRating(r.renterId!);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadExistingUserRating(int renterId) async {
    try {
      final existing = await context.read<UserRatingProvider>().getByReservation(
            renterId: renterId,
            reviewerId: Authorization.userId!,
            reservationId: widget.reservationId,
          );
      if (mounted) setState(() => _existingUserRating = existing);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }


  Widget _buildBody() {
    final r = _reservation!;
    final photos = r.property?.photos;
    final rawUrl = (photos != null && photos.isNotEmpty) ? photos.first.url : null;
    final photoUrl = (rawUrl != null && rawUrl.isNotEmpty) ? '${AppConfig.serverBase}$rawUrl' : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          photoUrl != null
              ? Image.network(
                  photoUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.reservationNumber ?? '',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ReservationStatus.chip(r.status),
                  ],
                ),
                const SizedBox(height: 16),

                _sectionTitle('Property'),
                _row('Name', r.property?.name),
                _row('City', r.property?.city?.name),
                _row('Address', r.property?.address),
                _row('Type', r.property?.propertyType?.name),
                const SizedBox(height: 16),

                _sectionTitle('Dates & Price'),
                _row('Check-in', _fmt(r.dateOfOccupancyStart)),
                _row('Check-out', _fmt(r.dateOfOccupancyEnd)),
                if (r.isDaily == true)
                  _row('Duration', '${r.numberOfDays} day(s)'),
                if (r.isMonthly == true)
                  _row('Duration', '${r.numberOfMonths} month(s)'),
                _row('Total price', '\$${r.totalPrice?.toStringAsFixed(2)}'),
                const SizedBox(height: 16),

                _sectionTitle('Guests & Parties'),
                _row('Guests', r.numberOfGuests?.toString()),
                _row(
                  'Renter',
                  '${r.renter?.person?.firstName ?? ''} ${r.renter?.person?.lastName ?? ''}'.trim(),
                  onTap: (r.renter != null || r.renterId != null)
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RenterProfileScreen(
                                  renter: r.renter, renterId: r.renterId)))
                      : null,
                ),
                _row(
                  'Client',
                  '${r.client?.person?.firstName ?? ''} ${r.client?.person?.lastName ?? ''}'.trim(),
                ),
                const SizedBox(height: 16),

                if (r.description != null && r.description!.isNotEmpty) ...[
                  _sectionTitle('Napomena'),
                  Text(r.description!,
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                ],

                if (r.confirmedAt != null) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Historija potvrde'),
                  if (r.confirmedByName != null && r.confirmedByName!.isNotEmpty)
                    _row('Potvrdio/la', r.confirmedByName),
                  _row('Datum potvrde',
                      DateFormat('dd.MM.yyyy HH:mm').format(r.confirmedAt!)),
                ],

                if (r.status == 3) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Detalji otkazivanja'),
                  if (r.cancelledByName != null && r.cancelledByName!.isNotEmpty)
                    _row('Otkazao/la', r.cancelledByName),
                  if (r.cancelledAt != null)
                    _row('Datum otkazivanja',
                        DateFormat('dd.MM.yyyy HH:mm').format(r.cancelledAt!)),
                  if (r.cancellationReason != null && r.cancellationReason!.isNotEmpty)
                    _row('Razlog', r.cancellationReason),
                ],

                if (_isPending) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Zahtjev je poslan iznajmljivaču. Čekate njegovu potvrdu.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _cancelling
                        ? const Center(child: CircularProgressIndicator())
                        : OutlinedButton.icon(
                            onPressed: _cancelPending,
                            icon: const Icon(Icons.undo, color: Colors.red),
                            label: const Text('Povuci zahtjev',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red)),
                          ),
                  ),
                ],

                if (_canPay) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Rezervacija je potvrđena! Izvršite plaćanje da biste je finalizirali.',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _paying
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _payReservation,
                            icon: const Icon(Icons.payment),
                            label: const Text('Plati putem PayPal-a'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF115892),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                  ),
                ],

                if (_canCancel)
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: _cancelling
                          ? const Center(child: CircularProgressIndicator())
                          : OutlinedButton.icon(
                              onPressed: _cancelReservation,
                              icon: const Icon(Icons.cancel_outlined,
                                  color: Colors.red),
                              label: const Text(
                                  'Otkaži rezervaciju i zatraži refund',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(color: Colors.red)),
                            ),
                    ),
                  ),

                if (r.status == 2) ...[
                  const SizedBox(height: 24),
                  const Text('Rate your experience',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewListScreen(
                                id: r.propertyId,
                                canReview: true,
                                reservationId: r.id,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Rate Property'),
                        ),
                      ),
                      if (r.renterId != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showRenterRatingSheet(
                                r.renterId!, widget.reservationId),
                            icon: const Icon(Icons.person_outline),
                            label: Text(_existingUserRating != null
                                ? 'Edit Renter Rating'
                                : 'Rate Renter'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenterRatingSheet(int renterId, int reservationId) async {
    int selectedStars =
        (_existingUserRating?.rating ?? 5).round().clamp(1, 5);
    final commentCtrl =
        TextEditingController(text: _existingUserRating?.description ?? '');
    bool submitting = false;
    final isUpdate = _existingUserRating != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isUpdate ? 'Edit Renter Rating' : 'Rate the Renter',
                  style:
                      const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Stars: '),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: selectedStars,
                    items: [1, 2, 3, 4, 5]
                        .map((n) => DropdownMenuItem(
                            value: n, child: Text('$n ★')))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => selectedStars = v ?? 5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          setSheetState(() => submitting = true);
                          try {
                            final rating = UserRating(
                              id: _existingUserRating?.id ?? 0,
                              renterId: renterId,
                              reviewerId: Authorization.userId,
                              reviewerName:
                                  '${Authorization.firstName ?? ''} ${Authorization.lastName ?? ''}'
                                      .trim(),
                              rating: selectedStars.toDouble(),
                              description: commentCtrl.text.trim().isEmpty
                                  ? null
                                  : commentCtrl.text.trim(),
                              reservationId: reservationId,
                            );
                            await context
                                .read<UserRatingProvider>()
                                .addRating(rating);
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            if (mounted) {
                              setState(() {
                                _existingUserRating = rating;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isUpdate
                                      ? 'Renter rating updated'
                                      : 'Renter rated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setSheetState(() => submitting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isUpdate ? 'Update' : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => commentCtrl.dispose());
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey)),
      );

  Widget _row(String label, String? value, {VoidCallback? onTap}) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 14,
                          color: onTap != null ? Colors.blue : null)),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right,
                      size: 16, color: Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap != null) return InkWell(onTap: onTap, child: content);
    return content;
  }

  String _fmt(DateTime? d) =>
      d != null ? DateFormat('dd.MM.yyyy').format(d) : '-';

  Widget _imagePlaceholder() => Container(
        height: 220,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Icon(Icons.home, size: 80, color: Colors.grey),
      );
}
