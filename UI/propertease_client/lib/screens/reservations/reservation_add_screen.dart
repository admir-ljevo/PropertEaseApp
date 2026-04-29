import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:propertease_client/models/property_reservation.dart';
import 'package:propertease_client/providers/property_reservation_provider.dart';
import 'package:provider/provider.dart';
import 'package:propertease_client/utils/authorization.dart';

import 'package:propertease_client/models/property.dart';
import 'reservation_detail_screen.dart';

const _kPrimary = Color(0xFF115892);

class ReservationAddScreen extends StatefulWidget {
  Property? property;
  ReservationAddScreen({super.key, this.property});

  @override
  State<StatefulWidget> createState() => ReservationAddScreenState();
}

class ReservationAddScreenState extends State<ReservationAddScreen> {
  EventList<Event> markedDatesList = EventList<Event>(events: {});
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late PropertyReservationProvider _reservationProvider;
  List<PropertyReservation>? _reservations;
  int selectedGuests = 1;
  double totalPrice = 0;
  DateTime? startDate;
  DateTime? endDate;
  Map<DateTime, List<dynamic>> markedDates = {};
  bool isLoading = true;
  bool isMonthly = false;
  bool isDaily = false;
  bool isActive = false;
  late int renterId;
  int numberOfMonths = 0;
  int numberOfDays = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();


  void setTotalPrice() {
    final days = calculateNumberOfDays(startDate, endDate);
    if (widget.property!.isMonthly!) {
      final fullMonths = days ~/ 30;
      final remaining = days - (fullMonths * 30);
      final dailyRate = widget.property!.monthlyPrice! / 30.0;
      totalPrice = widget.property!.monthlyPrice! * fullMonths + dailyRate * remaining;
    }
    if (widget.property!.isDaily!)
      totalPrice = widget.property!.dailyPrice! * days;
    setState(() {
      _priceController.text = totalPrice.toStringAsFixed(2);
    });
  }

  int? get userId => Authorization.userId;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  Future<void> addReservation() async {
    if (startDate == null || endDate == null) return;
    setState(() => _isSubmitting = true);

    try {
      final reservation = await _reservationProvider.createReservation({
        "propertyId": widget.property!.id,
        "clientId": userId,
        "renterId": renterId,
        "numberOfGuests": selectedGuests,
        "dateOfOccupancyStart": startDate!.toIso8601String(),
        "dateOfOccupancyEnd": endDate!.toIso8601String(),
        "totalPrice": totalPrice,
        "isMonthly": isMonthly,
        "isDaily": isDaily,
        "numberOfMonths": numberOfMonths,
        "numberOfDays": numberOfDays,
        "description": _descriptionController.text,
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReservationDetailsScreen(reservationId: reservation.id!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Greška: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  int calculateNumberOfMonths(DateTime? startDate, DateTime? endDate) {
    if (startDate != null && endDate != null) {
      int years = endDate.year - startDate.year;
      int months = endDate.month - startDate.month;
      int days = endDate.day - startDate.day - 1;

      if (days < 0) {
        months -= 1;
        days += DateTime(startDate.year, startDate.month + 1, 0).day;
      }

      int numberOfMonths = years * 12 + months + (days > 0 ? 1 : 0);
      return numberOfMonths;
    }
    return 0;
  }

  int calculateNumberOfDays(DateTime? startDate, DateTime? endDate) {
    if (startDate != null && endDate != null) {
      return endDate.difference(startDate).inDays;
    }
    return 0;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime initialDate = startDate ?? currentDate;

    while (!(await _isDateSelectable(initialDate))) {
      initialDate = initialDate.add(const Duration(days: 1));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: currentDate,
      lastDate: DateTime(2101),
      selectableDayPredicate: (DateTime date) {
        return _isDateSelectable(date);
      },
    );

    if (picked == null) return;

    if (picked != startDate) {
      setState(() {
        startDate = picked;
        if (widget.property!.isMonthly!)
          numberOfMonths = calculateNumberOfMonths(startDate, endDate);
        if (widget.property!.isDaily!)
          numberOfDays = calculateNumberOfDays(startDate, endDate);
        setTotalPrice();
      });
    }
  }

  bool _isDateSelectable(DateTime date) {
    if (_reservations != null) {
      for (final reservation in _reservations!) {
        if (!date.isBefore(reservation.dateOfOccupancyStart!) &&
            date.isBefore(reservation.dateOfOccupancyEnd!)) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime startDateValue = startDate ?? DateTime(2023);
    final DateTime minEndDate = isDaily
        ? startDateValue.add(const Duration(days: 1))
        : startDateValue.add(const Duration(days: 30));
    final DateTime currentDate = DateTime.now();

    DateTime? initialDate =
        minEndDate.isAfter(currentDate) ? minEndDate : currentDate;

    final DateTime searchLimit = DateTime.now().add(const Duration(days: 730));
    while (!_isEndDateSelectable(initialDate!, minEndDate)) {
      initialDate = initialDate.add(const Duration(days: 1));
      if (initialDate.isAfter(searchLimit)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Nema dostupnih datuma završetka za odabrani period.'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }
    }

    DateTime? pickedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Container(
            width: double.maxFinite,
            child: CalendarDatePicker(
              initialDate: initialDate!,
              firstDate: minEndDate,
              lastDate: DateTime(2101),
              selectableDayPredicate: (DateTime date) {
                return _isEndDateSelectable(date, minEndDate);
              },
              onDateChanged: (DateTime date) {
                pickedDate = date;
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );

    if (pickedDate != null && pickedDate != endDate) {
      setState(() {
        endDate = pickedDate;
        if (widget.property!.isMonthly!) {
          numberOfMonths = calculateNumberOfMonths(startDate, endDate);
        }
        if (widget.property!.isDaily!)
          numberOfDays = calculateNumberOfDays(startDate, endDate);
        setTotalPrice();
      });
    }
  }

  bool _isEndDateSelectable(DateTime date, DateTime minEndDate) {
    if (date.isBefore(minEndDate)) return false;
    if (_reservations == null || startDate == null) return true;
    for (final r in _reservations!) {
      final rStart = r.dateOfOccupancyStart;
      final rEnd = r.dateOfOccupancyEnd;
      if (rStart == null || rEnd == null) continue;
      // Block if [startDate, date] would overlap [rStart, rEnd)
      if (startDate!.isBefore(rEnd) && date.isAfter(rStart)) return false;
    }
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reservationProvider = context.read<PropertyReservationProvider>();
    fetchReservations();
    isMonthly = widget.property!.isMonthly!;
    isDaily = widget.property!.isDaily!;
    isActive = true;
    renterId = widget.property!.applicationUserId!;
    _priceController.text = totalPrice.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _reservationProvider = context.read<PropertyReservationProvider>();
    fetchReservations();
    isActive = true;
    isMonthly = widget.property!.isMonthly!;
    isDaily = widget.property!.isDaily!;
    renterId = widget.property!.applicationUserId!;
    _priceController.text = totalPrice.toStringAsFixed(2);
  }

  Future<void> fetchReservations() async {
    setState(() => isLoading = true);
    try {
      final tempReservations = await _reservationProvider
          .getFiltered(filter: {"propertyId": widget.property!.id, "isActive": true});
      setState(() {
        _reservations = tempReservations.result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  String _fmt(DateTime? d) =>
      d != null ? '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}' : 'Odaberite datum';

  String get _durationLabel {
    if (startDate == null || endDate == null) return '—';
    if (isMonthly) return '$numberOfMonths mj.';
    if (isDaily) return '$numberOfDays dana';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property!;
    final photoUrl = (p.firstPhotoUrl != null && p.firstPhotoUrl!.isNotEmpty)
        ? '${AppConfig.serverBase}${p.firstPhotoUrl}'
        : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        title: const Text('Nova rezervacija',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPropertyCard(p, photoUrl),
                  const SizedBox(height: 16),
                  _buildDatesCard(),
                  const SizedBox(height: 16),
                  _buildGuestsCard(p),
                  const SizedBox(height: 16),
                  _buildPriceCard(p),
                  const SizedBox(height: 16),
                  _buildNotesCard(),
                  const SizedBox(height: 24),
                  _buildConfirmButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 40),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _kPrimary),
                        SizedBox(height: 20),
                        Text(
                          'Kreiranje rezervacije...',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Molimo pričekajte',
                          style: TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property p, String? photoUrl) {
    return _SectionCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: photoUrl != null
                ? Image.network(
                    photoUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoPlaceholder(),
                  )
                : _photoPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name ?? '',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _iconText(Icons.location_city, p.city?.name ?? ''),
                _iconText(Icons.home_work, p.propertyType?.name ?? ''),
                _iconText(Icons.place_outlined, p.address ?? ''),
                const SizedBox(height: 6),
                Chip(
                  label: Text(
                    isMonthly ? 'Mjesečno' : 'Dnevno',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: _kPrimary,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        width: 90,
        height: 90,
        color: Colors.grey.shade200,
        child: const Icon(Icons.home_work, size: 40, color: Colors.grey),
      );

  Widget _iconText(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _buildDatesCard() {
    return _SectionCard(
      title: 'Period boravka',
      titleIcon: Icons.calendar_month,
      child: Column(
        children: [
          _DateTile(
            label: 'Datum dolaska',
            value: _fmt(startDate),
            isSet: startDate != null,
            onTap: () => _selectStartDate(context),
          ),
          const Divider(height: 1),
          _DateTile(
            label: 'Datum odlaska',
            value: _fmt(endDate),
            isSet: endDate != null,
            onTap: startDate != null ? () => _selectEndDate(context) : null,
          ),
          if (startDate != null && endDate != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.timelapse, size: 18, color: _kPrimary),
                  const SizedBox(width: 8),
                  const Text('Trajanje:',
                      style: TextStyle(color: Colors.black54, fontSize: 14)),
                  const Spacer(),
                  Text(
                    _durationLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _kPrimary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestsCard(Property p) {
    final capacity = p.capacity ?? 1;
    return _SectionCard(
      title: 'Broj gostiju',
      titleIcon: Icons.people_outline,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              'Odaberite broj gostiju',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const Spacer(),
            _CounterButton(
              icon: Icons.remove,
              onTap: selectedGuests > 1
                  ? () => setState(() => selectedGuests--)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$selectedGuests',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary),
              ),
            ),
            _CounterButton(
              icon: Icons.add,
              onTap: selectedGuests < capacity
                  ? () => setState(() => selectedGuests++)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(Property p) {
    return _SectionCard(
      title: 'Pregled cijene',
      titleIcon: Icons.euro_outlined,
      child: Column(
        children: [
          if (p.isMonthly == true)
            _PriceRow(
              label: 'Cijena po mjesecu',
              value: '${p.monthlyPrice?.toStringAsFixed(2) ?? '—'} BAM',
            ),
          if (p.isDaily == true)
            _PriceRow(
              label: 'Cijena po danu',
              value: '${p.dailyPrice?.toStringAsFixed(2) ?? '—'} BAM',
            ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                const Text('Ukupno:',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const Spacer(),
                Text(
                  startDate != null && endDate != null
                      ? '${totalPrice.toStringAsFixed(2)} BAM'
                      : '—',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _SectionCard(
      title: 'Napomena',
      titleIcon: Icons.notes,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: TextField(
          controller: _descriptionController,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Unesite dodatne informacije (opcionalno)...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final canSubmit = startDate != null && endDate != null;
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? _kPrimary : Colors.grey.shade400,
          foregroundColor: Colors.white,
          elevation: canSubmit ? 3 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.send_outlined),
        label: const Text(
          'Pošalji zahtjev za rezervaciju',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: canSubmit ? () async => addReservation() : null,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Widget child;

  const _SectionCard({this.title, this.titleIcon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  if (titleIcon != null) ...[
                    Icon(titleIcon, size: 18, color: _kPrimary),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title!,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                        letterSpacing: 0.3),
                  ),
                ],
              ),
            ),
          if (title != null) const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isSet;
  final VoidCallback? onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.isSet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: isSet ? _kPrimary : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSet ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right,
                  color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? _kPrimary : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;

  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
