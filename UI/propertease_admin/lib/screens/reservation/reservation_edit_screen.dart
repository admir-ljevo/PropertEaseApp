import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/providers/property_reservation_provider.dart';
import 'package:provider/provider.dart';

class ReservationEditScreen extends StatefulWidget {
  PropertyReservation? reservation;
  ReservationEditScreen({Key? key, this.reservation}) : super(key: key);

  @override
  _ReservationEditScreenState createState() => _ReservationEditScreenState();
}

class _ReservationEditScreenState extends State<ReservationEditScreen> {
  late PropertyReservationProvider _propertyReservationProvider;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isActive = false;
  int _guestsValue = 0;

  TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _propertyReservationProvider = context.read<PropertyReservationProvider>();
    _selectedStartDate = widget.reservation?.dateOfOccupancyStart;
    _selectedEndDate = widget.reservation?.dateOfOccupancyEnd;
    _isActive = widget.reservation?.isActive ?? false;
    _guestsValue = widget.reservation?.numberOfGuests ?? 0;
    _descriptionController.text = widget.reservation?.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Reservation'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGuestsDropdown("Number of Guests", _guestsValue,
                      (int value) {
                    setState(() {
                      _guestsValue = value;
                    });
                  }),
                  _buildDateSelector("Reservation Start", _selectedStartDate,
                      () {
                    _selectDate(context, true);
                  }),
                  _buildDateSelector("Reservation End", _selectedEndDate, () {
                    _selectDate(context, false);
                  }),
                  CheckboxListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (newValue) {
                      setState(() {
                        _isActive = newValue ?? false;
                      });
                    },
                  ),
                  SizedBox(
                    height: 120,
                    child: TextField(
                      maxLines: null, // Allows for multiline input
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter description here',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _saveReservation();
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _selectedStartDate ?? DateTime.now()
          : _selectedEndDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
        } else {
          _selectedEndDate = picked;
        }
      });
    }
  }

  Widget _buildGuestsDropdown(
      String label, int value, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(labelText: label),
      value: value,
      onChanged: (value) {
        setState(() {
          _guestsValue = value ?? 0;
        });
      },
      items: List.generate(10, (index) => index + 1)
          .map((number) => DropdownMenuItem<int>(
                value: number,
                child: Text(number.toString()),
              ))
          .toList(),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    final formattedDate =
        date != null ? DateFormat('dd.MM.yyyy').format(date) : '';

    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Select $label',
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(formattedDate),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  void _saveReservation() {
    widget.reservation?.description = _descriptionController.text;
    final updatedReservation = widget.reservation;
    // Call the provider to update the reservation
    _propertyReservationProvider.updateAsync(
        updatedReservation!.id, updatedReservation);

    // Return to the previous screen
    Navigator.pop(context);
  }
}
