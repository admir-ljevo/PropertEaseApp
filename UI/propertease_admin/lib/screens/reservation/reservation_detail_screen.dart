import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/providers/payment_provider.dart';
import 'package:propertease_admin/providers/property_reservation_provider.dart';
import 'package:propertease_admin/screens/reservation/reservation_edit_screen.dart';
import 'package:propertease_admin/screens/users/user_profile_screen.dart';
import 'package:propertease_admin/utils/reservation_status.dart';

class ReservationDetailsScreen extends StatefulWidget {
  final PropertyReservation? reservation;
  const ReservationDetailsScreen({super.key, this.reservation});

  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  bool _cancelling = false;
  bool _confirming = false;
  PropertyReservation? _freshReservation;

  @override
  void initState() {
    super.initState();
    _loadFresh();
  }

  Future<void> _loadFresh() async {
    final id = widget.reservation?.id;
    if (id == null) return;
    try {
      final r = await context.read<PropertyReservationProvider>().getById(id);
      if (mounted) setState(() => _freshReservation = r);
    } catch (_) {}
  }

  Future<void> _confirmReservation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda rezervacije'),
        content: const Text('Da li ste sigurni da želite potvrditi ovu rezervaciju? Klijent će biti obaviješten da izvrši plaćanje.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<PropertyReservationProvider>();
    setState(() => _confirming = true);
    try {
      final id = (_freshReservation ?? widget.reservation)!.id!;
      await provider.confirmReservation(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rezervacija potvrđena. Klijent je obaviješten.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<String?> _askCancellationReason(
      String title, String actionLabel) async {
    final controller = TextEditingController();
    String? errorText;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unesite razlog otkazivanja:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Npr. Nekretnina nije dostupna u odabranom periodu...',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Odustani'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  setDialogState(() => errorText = 'Razlog je obavezan');
                  return;
                }
                Navigator.of(ctx).pop(controller.text.trim());
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectReservation() async {
    final reason = await _askCancellationReason('Odbijanje zahtjeva', 'Odbij');
    if (reason == null || !mounted) return;

    final provider = context.read<PropertyReservationProvider>();
    setState(() => _cancelling = true);
    try {
      await provider.cancelReservation((_freshReservation ?? widget.reservation)!, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zahtjev odbijen.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pop(true);
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
    final reason = await _askCancellationReason(
        'Otkazivanje rezervacije', 'Otkaži i refunduj');
    if (reason == null || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await context
          .read<PaymentProvider>()
          .refundReservation((_freshReservation ?? widget.reservation)!.id!, isClient: false, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rezervacija otkazana. Refund je u obradi.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final r = _freshReservation ?? widget.reservation;
    if (r == null) {
      return const Scaffold(body: Center(child: Text('Rezervacija nije pronađena')));
    }

    final clientName =
        '${r.client?.person?.firstName ?? ''} ${r.client?.person?.lastName ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(r.reservationNumber ?? 'Detalji rezervacije'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Uredi rezervaciju',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReservationEditScreen(reservation: r),
              ),
            ).then((_) => setState(() {})),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              context,
              title: 'Informacije o rezervaciji',
              icon: Icons.receipt_long,
              children: [
                _row('Broj rezervacije', r.reservationNumber),
                _row('Nekretnina', r.property?.name),
                _row('Klijent', clientName.isNotEmpty ? clientName : null,
                    onTap: r.clientId != null
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    UserProfileScreen(userId: r.clientId)))
                        : null),
                _row('Broj gostiju', r.numberOfGuests?.toString()),
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              title: 'Datumi i trajanje',
              icon: Icons.calendar_today,
              children: [
                _row('Početak', r.dateOfOccupancyStart != null
                    ? DateFormat('dd.MM.yyyy').format(r.dateOfOccupancyStart!)
                    : null),
                _row('Kraj', r.dateOfOccupancyEnd != null
                    ? DateFormat('dd.MM.yyyy').format(r.dateOfOccupancyEnd!)
                    : null),
                _row('Broj dana', r.numberOfDays?.toString()),
                _row('Broj mjeseci', r.numberOfMonths?.toString()),
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              title: 'Cijena i status',
              icon: Icons.attach_money,
              children: [
                _row('Ukupna cijena', r.totalPrice != null ? '${r.totalPrice} KM' : null),
                _rowBool('Dnevna rezervacija', r.isDaily),
                _rowBool('Mjesečna rezervacija', r.isMonthly),
                _rowWidget('Status', ReservationStatus.chip(r.status)),
              ],
            ),
            if (r.description != null && r.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCard(
                context,
                title: 'Napomena',
                icon: Icons.notes,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      r.description!,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
            // ── Confirmed-by audit trail ────────────────────────────────
            if (r.confirmedAt != null) ...[
              const SizedBox(height: 12),
              _buildCard(
                context,
                title: 'Historija potvrde',
                icon: Icons.verified_outlined,
                children: [
                  if (r.confirmedByName != null && r.confirmedByName!.isNotEmpty)
                    _row('Potvrdio/la', r.confirmedByName),
                  _row('Datum potvrde',
                      DateFormat('dd.MM.yyyy HH:mm').format(r.confirmedAt!)),
                ],
              ),
            ],
            // ── Cancellation details ────────────────────────────────────
            if (r.status == 3) ...[
              const SizedBox(height: 12),
              _buildCard(
                context,
                title: 'Detalji otkazivanja',
                icon: Icons.cancel_outlined,
                children: [
                  if (r.cancelledByName != null && r.cancelledByName!.isNotEmpty)
                    _row('Otkazao/la', r.cancelledByName),
                  if (r.cancelledAt != null)
                    _row('Datum otkazivanja',
                        DateFormat('dd.MM.yyyy HH:mm').format(r.cancelledAt!)),
                  if (r.cancellationReason != null && r.cancellationReason!.isNotEmpty)
                    _row('Razlog', r.cancellationReason),
                ],
              ),
            ],
            // ── Pending: confirm or reject ──────────────────────────────
            if (r.status == 0) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Zahtjev čeka potvrdu.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_confirming || _cancelling)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmReservation,
                        icon: const Icon(Icons.check),
                        label: const Text('Potvrdi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _rejectReservation,
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Odbij',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],

            // ── Confirmed: allow cancel with refund ─────────────────────
            if (r.status == 1) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _cancelling
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                        onPressed: _cancelReservation,
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.red),
                        label: const Text(
                            'Otkaži rezervaciju i refunduj',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red)),
                      ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value, {VoidCallback? onTap}) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: onTap != null ? Colors.blue : null,
                    ),
                  ),
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
    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }

  Widget _rowWidget(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: const TextStyle(color: Colors.black54, fontSize: 14)),
          ),
          value,
        ],
      ),
    );
  }

  Widget _rowBool(String label, bool? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          Icon(
            value == true ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: value == true ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Text(
            value == true ? 'Da' : 'Ne',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: value == true ? Colors.green.shade700 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
