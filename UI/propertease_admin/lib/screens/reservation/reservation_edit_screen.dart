import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/providers/property_reservation_provider.dart';
import 'package:propertease_admin/utils/reservation_status.dart';
import 'package:provider/provider.dart';

class ReservationEditScreen extends StatefulWidget {
  final PropertyReservation? reservation;
  const ReservationEditScreen({Key? key, this.reservation}) : super(key: key);

  @override
  State<ReservationEditScreen> createState() => _ReservationEditScreenState();
}

class _ReservationEditScreenState extends State<ReservationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late PropertyReservationProvider _reservationProvider;
  late TextEditingController _descriptionController;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isMonthly = true;
  int _guests = 1;

  bool _submitted = false;

  int get _computedDays =>
      (_startDate != null && _endDate != null && _endDate!.isAfter(_startDate!))
          ? _endDate!.difference(_startDate!).inDays
          : 0;

  int get _computedMonths => (_computedDays / 30).floor();

  @override
  void initState() {
    super.initState();
    _reservationProvider = context.read<PropertyReservationProvider>();
    final r = widget.reservation;
    _startDate = r?.dateOfOccupancyStart;
    _endDate = r?.dateOfOccupancyEnd;
    _isMonthly = r?.isMonthly ?? true;
    _guests = r?.numberOfGuests ?? 1;
    _descriptionController = TextEditingController(text: r?.description ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String? _validateDateRange() {
    if (_startDate == null) return 'Odaberite datum početka rezervacije';
    if (_endDate == null) return 'Odaberite datum kraja rezervacije';
    if (!_endDate!.isAfter(_startDate!)) {
      return 'Datum kraja mora biti nakon datuma početka';
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final formValid = _formKey.currentState!.validate();
    final dateError = _validateDateRange();
    if (!formValid || dateError != null) return;

    final r = widget.reservation;
    if (r == null) return;

    r.numberOfGuests = _guests;
    r.dateOfOccupancyStart = _startDate;
    r.dateOfOccupancyEnd = _endDate;
    r.isMonthly = _isMonthly;
    r.isDaily = !_isMonthly;
    r.description = _descriptionController.text;

    try {
      await _reservationProvider.updateAsync(r.id, r);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Rezervacija ${r.reservationNumber ?? "#${r.id}"} uspješno ažurirana'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri ažuriranju rezervacije: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final clientName =
        '${r?.client?.person?.firstName ?? ''} ${r?.client?.person?.lastName ?? ''}'
            .trim();
    final dateError = _submitted ? _validateDateRange() : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(r?.reservationNumber ?? 'Uredi rezervaciju'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Spremi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: 'Informacije o rezervaciji',
                icon: Icons.receipt_long,
                children: [
                  _infoRow('Broj rezervacije', r?.reservationNumber),
                  _infoRow('Nekretnina', r?.property?.name),
                  _infoRow('Klijent',
                      clientName.isNotEmpty ? clientName : null),
                ],
              ),
              const SizedBox(height: 12),

              _buildCard(
                title: 'Gosti i datumi',
                icon: Icons.people,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _guests,
                          decoration: const InputDecoration(
                            labelText: 'Broj gostiju',
                            prefixIcon: Icon(Icons.people),
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(20, (i) => i + 1).map((n) {
                            return DropdownMenuItem(
                                value: n, child: Text('$n'));
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _guests = val ?? 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<bool>(
                          value: _isMonthly,
                          decoration: const InputDecoration(
                            labelText: 'Tip najma',
                            prefixIcon: Icon(Icons.schedule),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: true, child: Text('Mjesečno')),
                            DropdownMenuItem(
                                value: false, child: Text('Dnevno')),
                          ],
                          onChanged: (val) =>
                              setState(() => _isMonthly = val ?? true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDatePicker(
                    label: 'Početak rezervacije',
                    date: _startDate,
                    onTap: () => _pickDate(true),
                    errorText: _submitted && _startDate == null
                        ? 'Odaberite datum početka rezervacije'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDatePicker(
                    label: 'Kraj rezervacije',
                    date: _endDate,
                    onTap: () => _pickDate(false),
                    errorText: dateError != null && _startDate != null
                        ? dateError
                        : null,
                  ),
                  if (_computedDays > 0) ...[
                    const SizedBox(height: 12),
                    _durationSummary(),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              _buildCard(
                title: 'Cijena',
                icon: Icons.attach_money,
                children: [
                  TextFormField(
                    initialValue: (widget.reservation?.totalPrice ?? 0) > 0
                        ? widget.reservation!.totalPrice!.toStringAsFixed(2)
                        : '—',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Ukupna cijena (KM)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildCard(
                title: 'Status',
                icon: Icons.info_outline,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 160,
                          child: Text('Trenutni status',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 14)),
                        ),
                        ReservationStatus.chip(widget.reservation?.status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildCard(
                title: 'Napomena',
                icon: Icons.notes,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Napišite napomenu (opcionalno)...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Spremi izmjene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
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
            Row(children: [
              Icon(icon, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style:
                    const TextStyle(color: Colors.black54, fontSize: 14)),
          ),
          Expanded(
            child: Text(value ?? '—',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderSide: errorText != null
                    ? const BorderSide(color: Colors.red)
                    : const BorderSide(),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: errorText != null
                    ? const BorderSide(color: Colors.red)
                    : const BorderSide(color: Colors.grey),
              ),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              date != null
                  ? DateFormat('dd.MM.yyyy').format(date)
                  : 'Odaberi datum',
              style: TextStyle(
                fontSize: 14,
                color: date != null ? Colors.black87 : Colors.black38,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(errorText,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _durationSummary() {
    final parts = <String>[];
    if (_computedDays > 0) parts.add('$_computedDays dana');
    if (_computedMonths > 0) parts.add('$_computedMonths mj.');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            'Trajanje: ${parts.join('  ·  ')}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
