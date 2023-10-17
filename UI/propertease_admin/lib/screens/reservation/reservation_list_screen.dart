import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/property_provider.dart';
import 'package:propertease_admin/providers/property_reservation_provider.dart';
import 'package:propertease_admin/providers/property_type_provider.dart';
import 'package:propertease_admin/screens/reservation/reservation_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/property.dart';
import '../../models/property_type.dart';
import '../../widgets/master_screen.dart';
import 'reservation_edit_screen.dart';

class ReservationListWidget extends StatefulWidget {
  const ReservationListWidget({super.key});

  @override
  State<ReservationListWidget> createState() => ReservationListWidgetState();
}

class ReservationListWidgetState extends State<ReservationListWidget> {
  late PropertyProvider _propertyProvider;
  late PropertyReservationProvider _reservationProvider;
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
  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      title_widget: const Text("Reservation List"),
      child: Column(children: [_buildContent(), _buildDataListView()]),
    );
  }

  String? userId;
  // Add a GlobalKey for the form
  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  PropertyType? _selectedProperty = null;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
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
      _fetchReservations();
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
      _fetchReservations();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _propertyProvider = context.read<PropertyProvider>();
    _reservationProvider = context.read<PropertyReservationProvider>();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();

    _fetchReservations();
  }

  Future<void> _handleDeleteReservation(int? reservationId) async {
    try {
      await _reservationProvider.deleteById(reservationId);
      await _fetchReservations();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print("Error deleting property: $error");
    }
  }

  Future<void> _fetchReservations() async {
    try {
      await getUserIdFromSharedPreferences();
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
      var reservations = await _reservationProvider.getFiltered(filter: {
        'propertyName': _nameController.text,
        'propertyTypeId': propertyTypeId,
        'dateOccupancyStarted': formattedStartDate,
        'dateOccupancyEnded': formattedEndDate,
        'totalPriceFrom': minPrice,
        'totalPriceTo': maxPrice,
        'isActive': _isAvailable,
        'renterId': int.tryParse(userId!),
      });

      setState(() {
        result = reservations;
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Widget _buildContent() {
    return Column(
      children: [
        const Row(
          children: [
            SizedBox(
              width: 100,
            ),
            Text(
              "Reservation list view",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF115892)),
            ),
            Spacer(), // To push the icon to the right side
            Icon(
              Icons
                  .calendar_month, // You can replace this with the building icon you want
              size: 80,
              color: Color(0xFF115892),
            ),
            SizedBox(
              width: 100,
            ),
          ],
        ),

        const Divider(
          thickness: 2,
          color: Colors.blue,
        ),

        _buildSearch(context),
        const Divider(
          thickness: 2,
          color: Colors.blue,
        ), // Your existing _buildSearch widget
      ],
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Property name', prefixIcon: Icon(Icons.search)),
              controller: _nameController,
              onChanged: (value) {
                _fetchReservations();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<PropertyType?>(
              value: _selectedProperty,
              onChanged: (PropertyType? newValue) async {
                setState(() {
                  _selectedProperty = newValue;
                  propertyTypeId = newValue?.id;
                });
                await _fetchReservations();
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextButton(
              onPressed: () {
                _selectDateStart(context); // Show date picker dialog
              },
              child: const Text('Reservation start'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextButton(
              onPressed: () {
                _selectDateEnd(context); // Show date picker dialog
              },
              child: const Text('Reservation end'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Price range from'),
              keyboardType: TextInputType.number,
              controller: _minPriceController,
              onChanged: (value) => _fetchReservations(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Price range to'),
              keyboardType: TextInputType.number,
              controller: _maxPriceController,
              onChanged: (value) => _fetchReservations(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<bool?>(
              value: _isAvailable,
              onChanged: (bool? newValue) {
                setState(() {
                  _isAvailable = newValue;
                });
                _fetchReservations();
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
          ),
          const SizedBox(
            width: 15,
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _selectedProperty = null;
                _isAvailable = null;
                propertyTypeId = null;
              });

              formKey.currentState?.reset();
              formattedEndDate = null;
              formattedStartDate = null;
              _maxPriceController.clear();
              _minPriceController.clear();
              _nameController.clear();
              await _fetchReservations();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear), // Add your desired icon here
                SizedBox(
                    width: 4), // Add some spacing between the icon and text
                Text("Clear filters"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDataListView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(
                label: Expanded(
                  child: Text(
                    "Property name",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    "Property type",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    "City",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    "Reservation start",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    "Reservation end",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    "Total price",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    "Reservation status",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    "Actions",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ],
            rows: result?.result
                    .map((PropertyReservation e) => DataRow(cells: [
                          DataCell(Text(e.property?.name ?? '/')),
                          DataCell(Text(e.property?.propertyType?.name ?? '/')),
                          DataCell(Text(e.property?.city?.name ?? '/')),
                          DataCell(Text(DateFormat('dd-MM-yyyy').format(
                              e.dateOfOccupancyStart ?? DateTime.now()))),
                          DataCell(Text(DateFormat('dd-MM-yyyy')
                              .format(e.dateOfOccupancyEnd ?? DateTime.now()))),
                          DataCell(Text(e.totalPrice.toString())),
                          if (e.isActive == true) ...[
                            const DataCell(Text('Occupied'))
                          ] else ...[
                            const DataCell(Text("Available")),
                          ],
                          DataCell(Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReservationEditScreen(
                                        reservation: e,
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.edit),
                              ),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text(
                                            "Are you sure you want to delete this reservation?"),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text("Cancel"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: const Text("Delete"),
                                            onPressed: () async {
                                              _handleDeleteReservation(e.id);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Icon(Icons.delete),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReservationDetailsScreen(
                                        reservation: e,
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.info),
                              )
                            ],
                          ))
                        ]))
                    .toList() ??
                [],
          ),
        ),
      ],
    );
  }
}
