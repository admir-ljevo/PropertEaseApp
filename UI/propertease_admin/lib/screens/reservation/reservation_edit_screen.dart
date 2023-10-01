import 'package:flutter/material.dart';
import 'package:propertease_admin/models/property.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/providers/property_provider.dart';
import 'package:propertease_admin/providers/property_reservation_provider.dart';

class ReservationEditScreen extends StatefulWidget {
  PropertyReservation? reservation;
  ReservationEditScreen({super.key, this.reservation});
  @override
  State<StatefulWidget> createState() => _ReservationEditScreenState();
}

class _ReservationEditScreenState extends State<ReservationEditScreen> {
  late PropertyProvider _propertyProvider;
  late PropertyReservationProvider _propertyReservationProvider;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }
}
