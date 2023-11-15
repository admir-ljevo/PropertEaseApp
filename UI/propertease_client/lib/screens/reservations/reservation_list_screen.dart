import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/models/property_reservation.dart';
import 'package:propertease_client/models/search_result.dart';
import 'package:propertease_client/providers/property_reservation_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/property.dart';
import '../../models/property_type.dart';
import '../../providers/property_provider.dart';
import '../../providers/property_type_provider.dart';
import 'reservation_detail_screen.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<StatefulWidget> createState() => ReservationListScreenState();
}

class ReservationListScreenState extends State<ReservationListScreen> {
  late PropertyReservationProvider _reservationProvider;
  late PropertyProvider _propertyProvider;
  late PropertyTypeProvider _propertyTypeProvider;
  SearchResult<PropertyReservation>? result;
  SearchResult<Property>? propertyResult;
  SearchResult<PropertyType>? propertyTypeResult;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? formattedEndDate;
  String? formattedStartDate;
  int? propertyTypeId;
  DateTime? selectedDateStart;
  DateTime? selectedDateEnd;
  bool? _isAvailable;
  SearchResult<PropertyReservation>? reservations;
  PropertyType? _selectedProperty = null;

  String? firstName;
  String? lastName;
  String? photoUrl;
  int? roleId;
  int? userId;
  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = int.tryParse(prefs.getString('userId')!)!;
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');

      photoUrl = prefs.getString('profilePhoto');
      roleId = prefs.getInt('roleId');
    });
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    getUserIdFromSharedPreferences();

    _propertyProvider = context.read<PropertyProvider>();
    _reservationProvider = context.read<PropertyReservationProvider>();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    _fetchReservations();
  }

  Future<void> _selectDateStart(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != DateTime.now()) {
      selectedDateStart = picked;

      formattedStartDate = DateFormat('yyyy-MM-dd').format(selectedDateStart!);
    }
  }

  Future<void> _selectDateEnd(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != DateTime.now()) {
      selectedDateEnd = picked;
      formattedEndDate = DateFormat('yyyy-MM-dd').format(selectedDateEnd!);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserIdFromSharedPreferences();
    _propertyProvider = context.read<PropertyProvider>();
    _reservationProvider = context.read<PropertyReservationProvider>();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();

    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    try {
      propertyResult = await _propertyProvider.get();
      propertyTypeResult = await _propertyTypeProvider.get();

      double? minPrice;
      double? maxPrice;
      if (_minPriceController.text.isNotEmpty) {
        minPrice = double.tryParse(_minPriceController.text);
      }
      if (_maxPriceController.text.isNotEmpty) {
        maxPrice = double.tryParse(_maxPriceController.text);
      }
      var tempReservations = await _reservationProvider.getFiltered(filter: {
        'propertyName': _nameController.text,
        'propertyTypeId': propertyTypeId,
        'dateOccupancyStartedStart': formattedStartDate,
        'dateOccupancyStartedEnd': formattedEndDate,
        'totalPriceFrom': minPrice,
        'totalPriceTo': maxPrice,
        'isActive': _isAvailable,
        'clientId': userId,
      });

      setState(() {
        reservations = tempReservations;
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("My reservations"),
      ),
      body: SingleChildScrollView(
          child: Column(
        children: [
          ElevatedButton(
              onPressed: () {
                _showFilterDialog(context);
              },
              child: Text("Filters")),
          _buildDataListView(),
        ],
      )),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Apply Filters"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Property name',
                      prefixIcon: Icon(Icons.search)),
                  controller: _nameController,
                  onChanged: (value) {
                    // Handle onChanged logic if needed
                  },
                ),
                DropdownButtonFormField<PropertyType?>(
                  value: _selectedProperty,
                  onChanged: (PropertyType? newValue) {
                    _selectedProperty = newValue!;
                    propertyTypeId = newValue.id;
                  },
                  items: (propertyTypeResult?.result ?? [])
                      .map<DropdownMenuItem<PropertyType?>>(
                    (PropertyType? propertyType) {
                      if (propertyType != null && propertyType.name != null) {
                        return DropdownMenuItem<PropertyType?>(
                          value: propertyType,
                          child: Text(propertyType.name!),
                        );
                      } else {
                        return const DropdownMenuItem<PropertyType?>(
                          value: null,
                          child: Text('Undefined'),
                        );
                      }
                    },
                  ).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Property type',
                  ),
                ),
                // Add more filter widgets here
                TextButton(
                  onPressed: () {
                    _selectDateStart(context);
                  },
                  child: const Text('Reservation start'),
                ),
                TextButton(
                  onPressed: () {
                    _selectDateEnd(context);
                  },
                  child: const Text('Reservation end'),
                ),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Price range from'),
                  keyboardType: TextInputType.number,
                  controller: _minPriceController,
                  onChanged: (value) {},
                ),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Price range to'),
                  keyboardType: TextInputType.number,
                  controller: _maxPriceController,
                  onChanged: (value) {},
                ),
                DropdownButtonFormField<bool?>(
                  value: _isAvailable,
                  onChanged: (bool? newValue) {
                    _isAvailable = newValue!;
                  },
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('All'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text('Available'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text('Occupied'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Available',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue),
              ),
              onPressed: () async {
                setState(() {
                  _selectedProperty = null;
                  propertyTypeId = null;
                  _isAvailable = null;
                  propertyTypeId = null;
                  formKey.currentState?.reset();
                  formattedEndDate = null;
                  formattedStartDate = null;
                  _maxPriceController.clear();
                  _minPriceController.clear();
                  _nameController.clear();
                });

                await _fetchReservations();
              },
              child: const Text(
                "Clear filters",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                    Colors.blue), // Set the background color to blue
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                    Colors.blue), // Set the background color to blue
              ),
              onPressed: () {
                // Apply filter logic here
                _fetchReservations();
                Navigator.of(context).pop();
              },
              child: const Text(
                "Apply",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataListView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(
            label: Text(
              "Property name",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          DataColumn(
            label: Text(
              "Property type",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          DataColumn(
            label: Text(
              "City",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          DataColumn(
            label: Text(
              "Reservation start",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          DataColumn(
            label: Text(
              "Reservation end",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          DataColumn(
            label: Text(
              "Total price",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          DataColumn(
            label: Text(
              "Reservation status",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
        rows: reservations?.result
                .map(
                  (PropertyReservation e) => DataRow(
                    cells: [
                      DataCell(Text(e.property?.name ?? '/')),
                      DataCell(Text(e.property?.propertyType?.name ?? '/')),
                      DataCell(Text(e.property?.city?.name ?? '/')),
                      DataCell(
                        Text(
                          DateFormat('dd-MM-yyyy')
                              .format(e.dateOfOccupancyStart ?? DateTime.now()),
                        ),
                      ),
                      DataCell(
                        Text(
                          DateFormat('dd-MM-yyyy')
                              .format(e.dateOfOccupancyEnd ?? DateTime.now()),
                        ),
                      ),
                      DataCell(Text(e.totalPrice.toString())),
                      DataCell(
                          Text(e.isActive == true ? 'Active' : 'Inactive')),
                    ],
                    onSelectChanged: (_) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ReservationDetailsScreen(
                            reservation: e,
                          ),
                        ),
                      );
                    },
                  ),
                )
                .toList() ??
            [],
      ),
    );
  }

// Function to navigate to a different screen
  void navigateToDetailsScreen(PropertyReservation reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReservationDetailsScreen(reservation: reservation),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();

    super.dispose();
  }
}
