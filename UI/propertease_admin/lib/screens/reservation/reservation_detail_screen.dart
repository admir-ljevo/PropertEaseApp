import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/providers/property_provider.dart';
import 'package:propertease_admin/providers/property_reservation_provider.dart';
import 'package:provider/provider.dart';

class ReservationDetailsScreen extends StatefulWidget {
  PropertyReservation? reservation;
  ReservationDetailsScreen({super.key, this.reservation});
  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailsScreen> {
  late PropertyProvider _propertyProvider;
  late PropertyReservationProvider _propertyReservationProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              color: Colors.grey[200], // Subdued background color
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("Reservation number:",
                      widget.reservation?.reservationNumber),
                  _buildDetailRow(
                      "Property name:", widget.reservation?.property?.name),
                  _buildDetailRow("Client name:",
                      "${widget.reservation?.client?.person?.firstName ?? ''} ${widget.reservation?.client?.person?.lastName ?? ''}"),
                  _buildDetailRow("Number of guests:",
                      widget.reservation?.numberOfGuests.toString()),
                  _buildDetailRow(
                      "Reservation start:",
                      widget.reservation?.dateOfOccupancyStart != null
                          ? DateFormat('dd.MM.yyyy')
                              .format(widget.reservation!.dateOfOccupancyStart!)
                          : ''),
                  _buildDetailRow(
                      "Reservation end:",
                      widget.reservation?.dateOfOccupancyEnd != null
                          ? DateFormat('dd.MM.yyyy')
                              .format(widget.reservation!.dateOfOccupancyEnd!)
                          : ''),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              color: Colors.grey[200], // Subdued background color
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("Number of days:",
                      widget.reservation?.numberOfDays.toString()),
                  _buildDetailRow("Number of months:",
                      widget.reservation?.numberOfMonths.toString() ?? '0'),
                  _buildDetailRow(
                      "Total price:",
                      "${widget.reservation?.totalPrice ?? '0'} BAM" ??
                          '0 BAM'),
                  _buildDetailRow("Monthly reservation:",
                      _buildIcon(widget.reservation?.isMonthly)),
                  _buildDetailRow("Daily reservation:",
                      _buildIcon(widget.reservation?.isDaily)),
                  _buildDetailRow(
                      "Active:", _buildIcon(widget.reservation?.isActive)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          value is Widget // Check if the value is a Widget
              ? value
              : Text(
                  value ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildIcon(bool? isActive) {
    return isActive == true
        ? const Icon(
            Icons.check,
            color: Colors.green,
            size: 24,
          )
        : const Icon(
            Icons.close,
            color: Colors.red,
            size: 24,
          );
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _propertyProvider = context.read<PropertyProvider>();
    _propertyReservationProvider = context.read<PropertyReservationProvider>();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
}
