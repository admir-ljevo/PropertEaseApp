import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:propertease_admin/models/property_type.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/property_type_provider.dart';
import 'package:provider/provider.dart';
import 'package:propertease_admin/providers/image_provider.dart';
import '../../models/city.dart';
import '../../models/photo.dart';
import '../../models/property.dart';
import '../../providers/city_provider.dart';
import '../../providers/property_provider.dart';
import 'package:image_picker/image_picker.dart';

class PropertyAddScreen extends StatefulWidget {
  Property? property;

  PropertyAddScreen({super.key});

  @override
  State<PropertyAddScreen> createState() => _PropertyAddScreenState();
}

class _PropertyAddScreenState extends State<PropertyAddScreen> {
  Property property = Property();
  final TextEditingController _propertyNameController = TextEditingController();
  final TextEditingController _propertyAdressController =
      TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _gardenSizeController = TextEditingController();
  final TextEditingController _squareMetersController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late Photo insertPhoto;
  final _formKey = GlobalKey<FormState>();
  final _form2Key = GlobalKey<FormState>();

  SearchResult<PropertyType>? propertyTypeResult;
  SearchResult<City>? cityResult;
  int currentImageIndex = 0;
  int maxImagesToShow = 5;
  int startIndex = 5;
  Property? editedProperty;
  int? parsedCapacity;
  double? parsedPrice;
  List<Photo> images = [];
  String? displayedImageUrl;
  int? parsedGardenSize;
  int? parsedSquareMeters;
  bool _isFormValid = true;
  List<TextEditingController> _textControllers = [];
  final ImagePicker _picker = ImagePicker();

  // Create a method to fetch images
  void fetchImages() async {
    // Get the photo provider from the context
    final photoProvider = context.read<PhotoProvider>();

    final propertyId = property.id; // Replace with the actual property ID
    final fetchedImages = await photoProvider.getImagesByProperty(propertyId);

    setState(() {
      images = fetchedImages;
      if (images.isNotEmpty) displayedImageUrl = images[0].url;
    });
  }

  void _updateFormValidation(formKey) {
    final form = formKey.currentState;
    if (form != null) {
      setState(() {
        _isFormValid = form.validate();
      });
    }
  }

  @override
  void dispose() {
    // Dispose of the TextEditingController when the widget is disposed
    _propertyNameController.dispose();
    _propertyAdressController.dispose();
    _priceController.dispose();
    _gardenSizeController.dispose();
    _squareMetersController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _initialValue = {};
  late PropertyTypeProvider _propertyTypeProvider;
  late CityProvider _cityProvider;
  late PropertyProvider _propertyProvider;
  late PhotoProvider _photoProvider;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    _cityProvider = context.read<CityProvider>();
    _propertyProvider = context.read<PropertyProvider>();
    _photoProvider = context.read<PhotoProvider>();

    initForm();
  }

  @override
  void initState() {
    super.initState();
  }

  Future initForm() async {
    propertyTypeResult = await _propertyTypeProvider.get();
    cityResult = await _cityProvider.get();
    print(propertyTypeResult?.result);
    fetchImages();
  }

  void goToPreviousImage() {
    if (currentImageIndex > 0) {
      setState(() {
        currentImageIndex--;
        displayedImageUrl = images[currentImageIndex].url;
      });
    }
  }

  void goToNextImage() {
    if (currentImageIndex < images.length - 1) {
      setState(() {
        currentImageIndex++;
        displayedImageUrl = images[currentImageIndex].url;
      });
    }
  }

  File? _imageFile;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        insertPhoto = Photo(0, 'a', property.id, _imageFile);
        print(insertPhoto.createdAt);
        insertPhoto.file = _imageFile;
        _photoProvider.addPhoto(insertPhoto);
      });
    }
  }

  Widget buildImageRow(
      int currentImageIndex, String displayedImageUrl, List<Photo> images) {
    List<Widget> imageWidgets = [];
    int rangeFrom = 2, rangeTo = 2;
    if (currentImageIndex == 0) {
      rangeFrom = 0;
      rangeTo = 4;
    }

    if (currentImageIndex == 1) {
      rangeFrom = 1;
      rangeTo = 3;
    }
    if (currentImageIndex >= 2 && currentImageIndex >= images.length - 3) {
      rangeFrom = 2;
      rangeTo = 2;
    }
    if (currentImageIndex > 2 && currentImageIndex == images.length - 2) {
      rangeFrom = 3;
      rangeTo = 1;
    }
    if (currentImageIndex > 2 && currentImageIndex == images.length - 1) {
      rangeFrom = 4;
      rangeTo = 0;
    }
    for (int i = currentImageIndex - rangeFrom;
        i <= currentImageIndex + rangeTo;
        i++) {
      if (i >= 0 && i < images.length) {
        imageWidgets.add(
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Opacity(
              opacity: images[i].url == displayedImageUrl ? 0.3 : 1.0,
              child: Image.network(
                "https://localhost:44340/${images[i].url}",
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: imageWidgets,
    );
  }

  void showSuccessMessageImage() {
    const snackBar = SnackBar(
      content: Text('Image uploaded successfully!'),
      duration: Duration(seconds: 3),
      backgroundColor: Colors.green, // Adjust duration as needed
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showSuccessMessageEdit(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors
            .green, // Set the background color to green (or your desired color)
      ),
    );
  }

  void showErrorMessageEdit(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors
            .red, // Set the background color to green (or your desired color)
      ),
    );
  }

  Future updateProperty() async {
    if (_isFormValid == true) {
      parsedPrice = double.tryParse(_priceController.text);
      parsedGardenSize = int.tryParse(_gardenSizeController.text);
      parsedSquareMeters = int.tryParse(_squareMetersController.text);
      if (property.isDaily == true) {
        property.dailyPrice = parsedPrice;
        property.monthlyPrice = 0;
      }

      if (property.isMonthly == true) {
        property.monthlyPrice = parsedPrice;
        property.dailyPrice = 0;
      }
      property.createdAt = DateTime.now();
      property.gardenSize = parsedGardenSize;
      property.squareMeters = parsedSquareMeters;
      property.name = _propertyNameController.text;
      property.address = _propertyAdressController.text;
      property.description = _descriptionController.text;
      property = await _propertyProvider.addAsync(property);
      showSuccessMessageEdit(context, 'Item updated successfully');
    } else
      showErrorMessageEdit(context, 'Validation error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property add Screen'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20.0,
                ), // Add spacing between the icon and text
                const Text(
                  'Edit Property',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                // New Row with the Stack widget and two columns of input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Existing Stack widget (image display with arrows)
                    Stack(
                      children: [
                        if (images.isNotEmpty)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxWidth:
                                          700, // Set the maximum width here
                                      maxHeight:
                                          300, // Set the maximum height here
                                    ),
                                    child: Stack(
                                      children: [
                                        // Container for Left Arrow
                                        Positioned(
                                          left: 20,
                                          top: 0,
                                          bottom: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.arrow_back),
                                            onPressed: goToPreviousImage,
                                            color: Colors.blue,
                                            iconSize:
                                                32, // Adjust the icon size here
                                          ),
                                        ),
                                        // Container for Image
                                        Center(
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              maxWidth:
                                                  600, // Set the maximum width for the image
                                              maxHeight:
                                                  300, // Set the maximum height for the image
                                            ),
                                            child: Image.network(
                                              "https://localhost:44340/${images[currentImageIndex].url}",
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        // Container for Right Arrow
                                        Positioned(
                                          right: 20,
                                          top: 0,
                                          bottom: 0,
                                          child: IconButton(
                                            icon:
                                                const Icon(Icons.arrow_forward),
                                            color: Colors.blue,
                                            onPressed: goToNextImage,
                                            iconSize:
                                                32, // Adjust the icon size here
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              SizedBox(
                                height: 50,
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: () async => {
                                    await pickImage(),
                                    setState(() {
                                      initForm();
                                    }),
                                    showSuccessMessageImage(),
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.photo), // Edit icon
                                      SizedBox(
                                          width:
                                              8), // Add some spacing between icon and label
                                      Text('Add image'), // Edit label
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Image.asset(
                            "assets/images/house_placeholder.jpg",
                            height: 300,
                            width: 300,
                            fit: BoxFit.cover,
                          ),
                      ],
                    ),

                    // New Row with two columns of input fields
                    SizedBox(
                      width: 250,
                      child: Form(
                        autovalidateMode:
                            AutovalidateMode.always, // Enable auto-validation
                        key: _formKey,
                        child: Column(
                          children: [
                            // Input Field 1
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Property name',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextFormField(
                                  controller: _propertyNameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Property name',
                                  ),
                                  onChanged: (_) {
                                    _updateFormValidation(
                                        _formKey); // Call this function whenever the text changes
                                  },
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter a property name';
                                    }

                                    return null; // Return null if the input is valid
                                  },
                                ),
                              ],
                            ),

                            // Input Field 2
                            DropdownButtonFormField<PropertyType>(
                              value: property
                                  .propertyType, // Set the initial value
                              onChanged: (PropertyType? newValue) {
                                setState(() {
                                  // Update the selected value when the user makes a selection
                                  property.propertyTypeId = newValue?.id;
                                });
                              },
                              items: (propertyTypeResult?.result ?? [])
                                  .map<DropdownMenuItem<PropertyType>>(
                                (PropertyType? propertyType) {
                                  if (propertyType != null &&
                                      propertyType.name != null) {
                                    return DropdownMenuItem<PropertyType>(
                                      value: propertyType,
                                      child: Text(propertyType.name!),
                                    );
                                  } else {
                                    return const DropdownMenuItem<PropertyType>(
                                      value:
                                          null, // Provide a default value or handle null differently
                                      child: Text(
                                        'Undefined', // Display something meaningful for null values
                                      ),
                                    );
                                  }
                                },
                              ).toList(),
                              decoration: const InputDecoration(
                                labelText: 'Property types',
                              ),
                            ),

                            // Input Field 3
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Address',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextFormField(
                                  // Set the initial value
                                  controller:
                                      _propertyAdressController, // Set the controller

                                  decoration: const InputDecoration(
                                    hintText: 'Address',
                                    // You can customize the appearance of the input field decoration here.
                                  ),
                                  onChanged: (_) {
                                    _updateFormValidation(
                                        _formKey); // Call this function whenever the text changes
                                  },
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter an address';
                                    }
                                    return null; // Return null if the input is valid
                                  },
                                  // Other properties for the TextFormField...
                                ),
                              ],
                            ),
                            // Input Field 4
                            DropdownButtonFormField<String>(
                              value: property.isMonthly == true
                                  ? 'Monthly'
                                  : property.isDaily == true
                                      ? 'Daily'
                                      : null, // Set the initial value based on the property values
                              onChanged: (String? newValue) {
                                setState(() {
                                  // Set property.isMonthly and property.isDaily based on the selection
                                  if (newValue == 'Monthly') {
                                    property.isMonthly = true;
                                    property.isDaily = false;
                                  } else if (newValue == 'Daily') {
                                    property.isMonthly = false;
                                    property.isDaily = true;
                                  }
                                });
                              },
                              items: ['Monthly', 'Daily'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              decoration: const InputDecoration(
                                labelText: 'Rent type',
                              ),
                            ),
                            TextFormField(
                              controller: _priceController,

                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Price (BAM)',
                              ),
                              onChanged: (_) {
                                _updateFormValidation(
                                    _formKey); // Call this function whenever the text changes
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'This field is required';
                                }
                                // Use a regex to check if the input consists of only digits

                                return null; // Return null if the input is valid
                              },
                              // Other properties for the TextFormField...
                            ),
                            DropdownButtonFormField<int>(
                              value: property.capacity, // Set the initial value
                              onChanged: (int? newValue) {
                                setState(() {
                                  // Update the selected value when the user makes a selection
                                  property.capacity = newValue;
                                });
                              },
                              items: [
                                0,
                                1,
                                2,
                                3,
                                4,
                                5,
                                6,
                                7,
                                8,
                                9
                              ] // List of integer options
                                  .map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value
                                      .toString()), // Display integer as a string
                                );
                              }).toList(),
                              decoration: const InputDecoration(
                                labelText: 'Max people',
                              ),
                            ),
                            DropdownButtonFormField<int>(
                              value: property.parkingSize ??
                                  0, // Set the initial value
                              onChanged: (int? newValue) {
                                setState(() {
                                  // Update the selected value when the user makes a selection
                                  property.parkingSize = newValue;
                                });
                              },
                              items: [
                                0,
                                1,
                                2,
                                3,
                                4,
                                5,
                                6,
                                7,
                                8,
                                9
                              ] // List of integer options
                                  .map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value
                                      .toString()), // Display integer as a string
                                );
                              }).toList(),
                              decoration: const InputDecoration(
                                labelText: 'Parking size',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Second Column with 5 input fields
                    SizedBox(
                      width: 250,
                      child: Form(
                        autovalidateMode:
                            AutovalidateMode.always, // Enable auto-validation
                        key: _form2Key,
                        child: Column(
                          children: [
                            // Input Field 6
                            DropdownButtonFormField<City?>(
                              value: property
                                  .city, // Set the initial value (selectedCity is a City? variable)
                              onChanged: (City? newValue) {
                                setState(() {
                                  // Update the selected value when the user makes a selection
                                  property.cityId = newValue?.id;
                                });
                              },
                              items: (cityResult?.result ?? [])
                                  .map<DropdownMenuItem<City?>>(
                                (City? city) {
                                  if (city != null && city.name != null) {
                                    return DropdownMenuItem<City?>(
                                      value:
                                          city, // Ensure each value is unique
                                      child: Text(city.name!),
                                    );
                                  } else {
                                    return const DropdownMenuItem<City?>(
                                      value:
                                          null, // Provide a default value or handle null differently
                                      child: Text(
                                        'Undefined', // Display something meaningful for null values
                                      ),
                                    );
                                  }
                                },
                              ).toList(),
                              decoration: const InputDecoration(
                                labelText: 'City',
                              ),
                            ),
                            // Input Field 7
                            DropdownButtonFormField<int>(
                              value: property.numberOfRooms ??
                                  0, // Set the initial value
                              onChanged: (int? newValue) {
                                setState(() {
                                  // Update the selected value when the user makes a selection
                                  property.numberOfRooms = newValue;
                                });
                              },
                              items: [
                                0,
                                1,
                                2,
                                3,
                                4,
                                5,
                                6,
                                7,
                                8,
                                9
                              ] // List of integer options
                                  .map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value
                                      .toString()), // Display integer as a string
                                );
                              }).toList(),
                              decoration: const InputDecoration(
                                labelText: 'Number of Rooms',
                              ),
                            ),
                            // Input Field 8
                            DropdownButtonFormField<int>(
                              value: property.numberOfBathrooms ??
                                  0, // Set the initial value
                              onChanged: (int? newValue) {
                                setState(() {
                                  // Update the selected value when the user makes a selection
                                  property.numberOfBathrooms = newValue;
                                });
                              },
                              items: [
                                0,
                                1,
                                2,
                                3,
                                4,
                                5,
                                6,
                                7,
                                8,
                                9
                              ] // List of integer options
                                  .map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value
                                      .toString()), // Display integer as a string
                                );
                              }).toList(),
                              decoration: const InputDecoration(
                                labelText: 'Number of Bahtrooms',
                              ),
                            ),
                            // Input Field 9
                            DropdownButtonFormField<int>(
                              value: property.garageSize ??
                                  0, // Set the initial value
                              onChanged: (int? newValue) {
                                setState(() {
                                  // Update the selected value when the user makes a selection
                                  property.garageSize = newValue;
                                });
                              },
                              items: [
                                0,
                                1,
                                2,
                                3,
                                4,
                                5,
                                6,
                                7,
                                8,
                                9
                              ] // List of integer options
                                  .map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value
                                      .toString()), // Display integer as a string
                                );
                              }).toList(),
                              decoration: const InputDecoration(
                                labelText: 'Garage capacity',
                              ),
                            ),
                            // Input Field 10

                            TextFormField(
                              controller: _squareMetersController,
                              keyboardType: TextInputType.numberWithOptions(),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter
                                    .digitsOnly, // Allow only digits
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Square meters',
                              ),
                              onChanged: (_) {
                                _updateFormValidation(
                                    _form2Key); // Call this function whenever the text changes
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'This field is required';
                                }
                                // Use a regex to check if the input consists of only digits
                                final isDigitsOnly = int.tryParse(value);
                                if (isDigitsOnly == null) {
                                  return 'Please enter a valid number';
                                }
                                return null; // Return null if the input is valid
                              },
                              // Other properties for the TextFormField...
                            ),
                            TextFormField(
                              controller: _gardenSizeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter
                                    .digitsOnly, // Allow only digits
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Garden size (Square meters)',
                              ),
                              onChanged: (_) {
                                _updateFormValidation(
                                    _form2Key); // Call this function whenever the text changes
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'This field is required';
                                }
                                // Use a regex to check if the input consists of only digits
                                final isDigitsOnly = int.tryParse(value);
                                if (isDigitsOnly == null) {
                                  return 'Please enter a valid number';
                                }
                                return null; // Return null if the input is valid
                              },
                              // Other properties for the TextFormField...
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(
                  color: Colors.blue,
                  thickness: 1.0,
                  height: 20.0,
                ),
                const SizedBox(
                  width: 50,
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 130,
                    ),
                    Container(
                      color: const Color.fromARGB(255, 246, 246, 246),
                      child: Row(
                        children: [
                          if (displayedImageUrl != null)
                            buildImageRow(
                                currentImageIndex, displayedImageUrl!, images),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(
                  color: Colors.blue,
                  thickness: 1.0,
                  height: 20.0,
                ),
                const SizedBox(
                  height: 30,
                ),
                Column(
                  children: [
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceEvenly, // Center content horizontally with spacing
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.isFurnished ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.isFurnished =
                                            newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Furnished'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value:
                                        property.hasOwnHeatingSystem ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasOwnHeatingSystem =
                                            newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Heating system'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.hasParking ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasParking = newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Parking'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.hasAirCondition ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasAirCondition =
                                            newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Air conditioning'),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.hasWiFi ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasWiFi = newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Wi-Fi'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.hasGarage ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasGarage = newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Garage'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.hasAlarm ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasAlarm = newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Alarm'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.hasTV ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasTV = newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('TV'),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.hasPool ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasPool = newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Pool'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.hasSurveilance ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasSurveilance =
                                            newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Surveilance'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.hasCableTV ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasCableTV = newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Cable TV'),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: property.hasBalcony ?? false,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        property.hasBalcony = newValue ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Balcony'),
                                ],
                              ),
                            ],
                          ),
                          // Add more columns as needed
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 1300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextFormField(
                            // Set the initial value
                            controller:
                                _descriptionController, // Set the controller

                            decoration: const InputDecoration(
                              hintText: 'Description',
                              // Add a border to the input field
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors
                                      .blue, // You can specify the border color here
                                ),
                              ),
                            ),
                            maxLines:
                                null, // Set maxLines to null for multiple lines
                            // Other properties for the TextFormField...
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      height: 50,
                      width: 90,
                      child: ElevatedButton(
                        onPressed: () async => updateProperty(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit), // Edit icon
                            SizedBox(
                                width:
                                    8), // Add some spacing between icon and label
                            Text('Edit'), // Edit label
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
