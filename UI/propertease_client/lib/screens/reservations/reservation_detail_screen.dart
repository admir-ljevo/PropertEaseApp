import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:provider/provider.dart';

import '../../models/property_reservation.dart';
import '../../providers/payment_provider.dart';
import '../../providers/property_reservation_provider.dart';
import '../users/renter_profile_screen.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _canCancel {
    final r = _reservation;
    if (r == null || r.isActive != true) return false;
    final checkIn = r.dateOfOccupancyStart;
    if (checkIn == null) return false;
    return checkIn.difference(DateTime.now()).inDays >= 7;
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
      _load(); // refresh
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
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
          // Header image
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
                // Reservation number + status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.reservationNumber ?? '',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: r.isActive == true
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        r.isActive == true ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: r.isActive == true
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
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
                  _sectionTitle('Additional information'),
                  Text(r.description!,
                      style: const TextStyle(fontSize: 15, height: 1.5)),
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
              ],
            ),
          ),
        ],
      ),
    );
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
