import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/image_provider.dart';
import 'package:propertease_admin/providers/property_provider.dart';
import 'package:propertease_admin/screens/property/property_detail_screen.dart';
import 'package:propertease_admin/screens/property/property_edit_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';

import '../../models/city.dart';
import '../../models/property.dart';
import '../../models/property_type.dart';
import '../../providers/city_provider.dart';
import '../../providers/property_type_provider.dart';
import '../../widgets/master_screen.dart';
import 'property_add_screen.dart';

class PropertyListWidget extends StatefulWidget {
  const PropertyListWidget({super.key});

  @override
  State<PropertyListWidget> createState() => PropertyListWidgetState();
}

class PropertyListWidgetState extends State<PropertyListWidget> {
  late PropertyProvider _propertyProvider;
  late PhotoProvider _photoProvider;
  late PropertyTypeProvider _propertyTypeProvider;
  late CityProvider _cityProvider;
  SearchResult<Property>? result;
  SearchResult<PropertyType>? propertyTypeResult;
  SearchResult<City>? cityResult;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  int? cityId;
  int? propertyTypeId;

  // Initialize the selected values here
  City? _selectedCity = null;
  PropertyType? _selectedProperty = null;
  bool? _isAvailable = null; // New variable for "Available" filter

  // Add a GlobalKey for the form
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _propertyProvider = context.read<PropertyProvider>();
    _photoProvider = context.read<PhotoProvider>();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    _cityProvider = context.read<CityProvider>();
    _fetchProperties();
  }

  @override
  void initState() {
    super.initState();
    _propertyProvider = context.read<PropertyProvider>();
    _photoProvider = context.read<PhotoProvider>();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    _cityProvider = context.read<CityProvider>();
    _fetchProperties();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      title_widget: const Text("Property List"),
      child: Column(children: [_buildContent(), _buildDataListView()]),
    );
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
              "Properties",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF115892)),
            ),
            Spacer(), // To push the icon to the right side
            Icon(
              Icons
                  .business, // You can replace this with the building icon you want
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

        Row(
          children: [
            const SizedBox(
              width: 100,
            ),
            const Text(
              "Property list view",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF115892)),
            ),
            const Spacer(), // To push the icon to the right side

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PropertyAddScreen(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Add some spacing between the icon and text
                      Text("Add new property"),
                      Icon(Icons.add), // Add your desired icon here
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 100,
            ),
          ],
        ),
        const Divider(
          thickness: 2,
          color: Colors.blue,
        ),

        _buildSearch(), // Your existing _buildSearch widget
      ],
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Property name',
                    prefixIcon: Icon(Icons.search),
                  ),
                  controller: _nameController,
                  onChanged: (value) async => await _fetchProperties(),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: DropdownButtonFormField<City?>(
                  key: UniqueKey(),
                  value: _selectedCity,
                  onChanged: (City? newValue) async {
                    setState(() {
                      _selectedCity = newValue;
                      cityId = newValue?.id;
                    });
                    await _fetchProperties();
                  },
                  items:
                      (cityResult?.result ?? []).map<DropdownMenuItem<City?>>(
                    (City? city) {
                      if (city != null && city.name != null ||
                          _selectedCity != null) {
                        return DropdownMenuItem<City?>(
                          value: city,
                          child: Text(city!.name!),
                        );
                      } else {
                        return const DropdownMenuItem<City?>(
                          value: null,
                          child: Text('Undefined'),
                        );
                      }
                    },
                  ).toList(),
                  decoration: const InputDecoration(
                    labelText: 'City',
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: DropdownButtonFormField<PropertyType?>(
                  value: _selectedProperty,
                  onChanged: (PropertyType? newValue) async {
                    setState(() {
                      _selectedProperty = newValue;
                      propertyTypeId = newValue?.id;
                    });
                    await _fetchProperties();
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
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: DropdownButtonFormField<bool?>(
                  value: _isAvailable,
                  onChanged: (bool? newValue) {
                    _fetchProperties();
                    setState(() {
                      _isAvailable = newValue;
                    });
                  },
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('All'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text('Available'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text('Rented'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Available',
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Min Price',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  controller: _minPriceController,
                  onChanged: (value) async {
                    await _fetchProperties();
                  },
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  controller: _maxPriceController,
                  onChanged: (value) async {
                    await _fetchProperties();
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _selectedCity = null;
                    _selectedProperty = null;
                    _isAvailable = null;
                    cityId = null;
                    propertyTypeId = null;
                  });

                  formKey.currentState?.reset();
                  await _fetchProperties();

                  _nameController.clear();
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
          const SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }

  Future<void> _fetchProperties() async {
    try {
      propertyTypeResult = await _propertyTypeProvider.get();
      cityResult = await _cityProvider.get();

      // Parse the minimum and maximum prices from the text input fields
      double? minPrice;
      double? maxPrice;
      if (_minPriceController.text.isNotEmpty) {
        minPrice = double.tryParse(_minPriceController.text);
      }
      if (_maxPriceController.text.isNotEmpty) {
        maxPrice = double.tryParse(_maxPriceController.text);
      }

      var properties = await _propertyProvider.getFiltered(filter: {
        'name': _nameController.text,
        'cityId': cityId,
        'propertyTypeId': propertyTypeId,
        'isAvailable': _isAvailable,
        // Include the price range filter
        'priceFrom': minPrice,
        'priceTo': maxPrice,
      });

      setState(() {
        result = properties;
      });
    } catch (error) {
      // Handle errors here
    }
  }

  Future<void> _handleDeleteProperty(int? propertyId) async {
    try {
      await _propertyProvider.deleteById(propertyId);

      await _fetchProperties();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print("Error deleting property: $error");
    }
  }

  Widget _buildDataListView() {
    return Expanded(
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
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
                  "Name",
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
                  "Address",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  "Unit price",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  "Vacancy status",
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
                  .map((Property e) => DataRow(cells: [
                        DataCell(Text(e.propertyType?.name ?? "/")),
                        DataCell(Text(e.name ?? "/")),
                        DataCell(Text(e.city?.name ?? "/")),
                        DataCell(Text(e.address ?? "/")),
                        if (e.isDaily == true)
                          DataCell(Text('${e.dailyPrice}BAM/Day' ?? "/")),
                        if (e.isMonthly == true)
                          DataCell(Text('${e.monthlyPrice}BAM/Month' ?? "/")),
                        if (e.isAvailable == true)
                          const DataCell(Text('Available')),
                        if (e.isAvailable == false)
                          const DataCell(Text('Rented')),
                        DataCell(
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PropertyEditScreen(
                                        property: e,
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.edit),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text(
                                            "Are you sure you want to delete this property?"),
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
                                              _handleDeleteProperty(e.id);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Icon(Icons.delete),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PropertyDetailScreen(
                                        property: e,
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.info),
                              ),
                            ],
                          ),
                        ),
                      ]))
                  .toList() ??
              [],
        ),
      ),
    );
  }
}
