import 'package:flutter/material.dart';
import 'package:propertease_client/providers/city_provider.dart';
import 'package:propertease_client/providers/image_provider.dart';
import 'package:propertease_client/providers/property_provider.dart';
import 'package:propertease_client/providers/property_type_provider.dart';
import 'package:propertease_client/widgets/master_screen.dart';
import 'package:provider/provider.dart';

import '../../models/city.dart';
import '../../models/property.dart';
import '../../models/property_type.dart';
import '../../models/search_result.dart';
import '../../utils/util.dart';
import 'property_details.dart';

class PropertyListWidget extends StatefulWidget {
  const PropertyListWidget({super.key});

  @override
  State<StatefulWidget> createState() => PropertyListWidgetState();
}

class PropertyListWidgetState extends State<PropertyListWidget> {
  late PropertyProvider _propertyProvider;
  late PropertyTypeProvider _propertyTypeProvider;
  late CityProvider _cityProvider;
  late PhotoProvider _photoProvider;
  SearchResult<Property>? result;
  SearchResult<PropertyType>? propertyTypeResult;
  SearchResult<City>? cityResult;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  int? cityId;
  int? propertyTypeId;

  City? _selectedCity = null;
  PropertyType? _selectedProperty = null;
  bool? _isAvailable = null; // New variable for "Available" filter
  String? userId;
  // Add a GlobalKey for the form
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _propertyProvider = context.read<PropertyProvider>();
    _cityProvider = context.read<CityProvider>();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    _photoProvider = context.read<PhotoProvider>();
  }

  Future<Image> getFirstImageByPropertyId(int? propertyId) async {
    return await _photoProvider.getFirstImageByPropertyId(propertyId!);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _propertyProvider = context.read<PropertyProvider>();

    _cityProvider = context.read<CityProvider>();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    _photoProvider = context.read<PhotoProvider>();

    _fetchProperties();
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
        'priceFrom': minPrice,
        'priceTo': maxPrice,
      });

      setState(() {
        result = properties;
      });
    } catch (error) {
      print(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      title_widget: const Text("Properties"),
      child: Column(
        children: <Widget>[
          const SizedBox(
            width: 100,
          ),
          const Text(
            "Property overview",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF115892),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "Search by property name",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) async {
                      await _fetchProperties();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                const Text(
                  "Filter",
                  style: TextStyle(fontSize: 24),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.filter_list,
                    size: 24,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          title: const Text("Filter Properties"),
                          children: [
                            Column(
                              children: [
                                DropdownButtonFormField<City?>(
                                  value: _selectedCity,
                                  onChanged: (City? newValue) async {
                                    setState(() {
                                      _selectedCity = newValue;
                                      cityId = newValue?.id;
                                    });
                                    await _fetchProperties();
                                  },
                                  items: (cityResult?.result ?? [])
                                      .map<DropdownMenuItem<City?>>(
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
                                DropdownButtonFormField<PropertyType?>(
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
                                      if (propertyType != null &&
                                          propertyType.name != null) {
                                        return DropdownMenuItem<PropertyType?>(
                                          value: propertyType,
                                          child: Text(propertyType.name!),
                                        );
                                      } else {
                                        return const DropdownMenuItem<
                                            PropertyType?>(
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
                                DropdownButtonFormField<bool?>(
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
                                TextFormField(
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
                                TextFormField(
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
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all(Colors.blue),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.clear,
                                        color: Colors.white,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                        "Clear filters",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(
            thickness: 2,
            color: Colors.blue,
          ),
          const SizedBox(height: 10.0),
          if (result == null)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (result!.count == 0)
            const Center(
              child: Text("No properties available."),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: result!.count,
                itemBuilder: (context, index) {
                  final currentProperty = result!.result[index];

                  // Call the function to get the image
                  return FutureBuilder<Image>(
                    future: getFirstImageByPropertyId(currentProperty.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        final image = snapshot.data;
                        if (image != null) {
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Center(
                                    child: Text(
                                      currentProperty.name ?? "",
                                      style: const TextStyle(
                                        fontSize:
                                            18, // Adjust the font size as needed
                                        fontWeight: FontWeight
                                            .bold, // You can change the font weight
                                        color: Colors
                                            .black, // Set the text color to your preference
                                      ),
                                      textAlign: TextAlign
                                          .center, // Center-align the text
                                    ),
                                  ),
                                  // Wrap the image and text in a Stack
                                  Stack(
                                    children: [
                                      // Image with BoxFit
                                      Image(
                                        image: image.image,
                                        fit: BoxFit.contain,
                                      ),
                                      Positioned(
                                        left: 8,
                                        bottom: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          color: currentProperty.isAvailable!
                                              ? Colors
                                                  .blue // Set background color for 'Available' (true)
                                              : Colors
                                                  .red, // Set background color for 'Occupied' (false)
                                          child: Text(
                                            currentProperty.isAvailable!
                                                ? 'Available'
                                                : 'Occupied',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  14, // Adjust the font size as needed
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'User rating: ${formatNumber(currentProperty.averageRating!)}/5',
                                          style: const TextStyle(
                                            fontSize:
                                                18, // Adjust the font size as needed
                                            fontWeight: FontWeight
                                                .bold, // You can change the font weight
                                            color: Colors
                                                .black, // Set the text color to your preference
                                          ),
                                        ),
                                        const Icon(Icons.star),
                                      ],
                                    ),
                                  ),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Property type: ${currentProperty.propertyType?.name}',
                                          style: const TextStyle(
                                            fontSize:
                                                18, // Adjust the font size as needed
                                            fontWeight: FontWeight
                                                .bold, // You can change the font weight
                                            color: Colors
                                                .black, // Set the text color to your preference
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'City: ${currentProperty.city?.name}',
                                          style: const TextStyle(
                                            fontSize:
                                                18, // Adjust the font size as needed
                                            fontWeight: FontWeight
                                                .bold, // You can change the font weight
                                            color: Colors
                                                .black, // Set the text color to your preference
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            currentProperty.numberOfRooms!
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize:
                                                  18, // Adjust the font size as needed
                                              fontWeight: FontWeight
                                                  .bold, // You can change the font weight
                                              color: Colors
                                                  .black, // Set the text color to your preference
                                            ),
                                          ),
                                          const Icon(
                                            Icons.bed,
                                            color: Colors.blue,
                                            size: 30,
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            currentProperty.numberOfBathrooms!
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize:
                                                  18, // Adjust the font size as needed
                                              fontWeight: FontWeight
                                                  .bold, // You can change the font weight
                                              color: Colors
                                                  .black, // Set the text color to your preference
                                            ),
                                          ),
                                          const Icon(
                                            Icons.bathtub,
                                            color: Colors.blue,
                                            size: 30,
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            currentProperty.parkingSize!
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize:
                                                  18, // Adjust the font size as needed
                                              fontWeight: FontWeight
                                                  .bold, // You can change the font weight
                                              color: Colors
                                                  .black, // Set the text color to your preference
                                            ),
                                          ),
                                          const Icon(
                                            Icons.garage,
                                            color: Colors.blue,
                                            size: 30,
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            currentProperty.squareMeters!
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize:
                                                  18, // Adjust the font size as needed
                                              fontWeight: FontWeight
                                                  .bold, // You can change the font weight
                                              color: Colors
                                                  .black, // Set the text color to your preference
                                            ),
                                          ),
                                          const Icon(
                                            Icons.aspect_ratio,
                                            color: Colors.blue,
                                            size: 30,
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  if (currentProperty.isDaily!)
                                    Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(
                                              15.0), // Adjust the radius as needed
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "Price: ${currentProperty.dailyPrice!}BAM/Day",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  if (currentProperty.isMonthly!)
                                    Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(
                                              15.0), // Adjust the radius as needed
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "Price: ${currentProperty.monthlyPrice!}BAM/Month",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PropertyDetailsScreen(
                                              property: currentProperty,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.blue),
                                      ),
                                      child: const SizedBox(
                                        width: 100,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Details",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20),
                                            ),
                                            Icon(
                                              Icons.menu,
                                              color: Colors.white,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }
                      return const CircularProgressIndicator();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
