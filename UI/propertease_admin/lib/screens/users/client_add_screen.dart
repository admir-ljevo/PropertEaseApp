import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/person.dart';
import 'package:provider/provider.dart';

import '../../models/application_role.dart';
import '../../models/application_user.dart';
import '../../models/city.dart';
import '../../models/search_result.dart';
import '../../providers/application_role_provider.dart';
import '../../providers/application_user_provider.dart';
import '../../providers/city_provider.dart';

class ClientAddScreen extends StatefulWidget {
  const ClientAddScreen({super.key});

  @override
  State<StatefulWidget> createState() => ClientAddScreenState();
}

class ClientAddScreenState extends State<ClientAddScreen> {
  late ApplicationUser newUser = ApplicationUser();
  File? selectedImage;
  City? selectedCity;
  SearchResult<City>? cityResult;
  SearchResult<ApplicationRole>? roleResult;
  final _formKey = GlobalKey<FormState>();

  late CityProvider _cityProvider;
  late RoleProvider _roleProvider;
  late UserProvider _userProvider;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _jmbgController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  int selectedGender = 0; // 0 for Male, 1 for Female

  Future<void> addClient() async {
    newUser.id = 0;
    newUser.person = Person();
    newUser.person?.firstName = _firstNameController.text;
    newUser.person?.lastName = _lastNameController.text;
    newUser.userName = _userNameController.text;
    newUser.email = _emailController.text;
    newUser.phoneNumber = _phoneNumberController.text;
    newUser.person?.address = _addressController.text;
    newUser.person?.postCode = _postalCodeController.text;
    newUser.person?.jmbg = _jmbgController.text;
    newUser.person?.gender = selectedGender;
    newUser.person?.position = 0;
    newUser.person?.birthDate = selectedDate;
    newUser.person?.placeOfResidenceId = selectedCity!.id;
    if (_formKey.currentState!.validate()) {
      await _userProvider.addClient(newUser, _passwordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Client ${newUser.person?.firstName} ${newUser.person?.lastName} added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  DateTime selectedDate = DateTime.now();
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        newUser.file = selectedImage;
        newUser.person?.profilePhoto = selectedImage?.path;
        newUser.person?.profilePhotoThumbnail = selectedImage?.path;
      });
    }
  }

  Future<void> _fetchCities() async {
    var cities = await _cityProvider.get();
    setState(() {
      cityResult = cities;
      selectedCity = cities.result[0];
    });
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _cityProvider = context.read<CityProvider>();
    _roleProvider = context.read<RoleProvider>();
    _userProvider = context.read<UserProvider>();
    _fetchCities();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _cityProvider = context.read<CityProvider>();
    _roleProvider = context.read<RoleProvider>();
    _userProvider = context.read<UserProvider>();
    _fetchCities();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: const Text("Add new client")),
      body: Form(
          key: _formKey,
          child: SingleChildScrollView(
              child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 34.0,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'New client',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                thickness: 2,
                color: Colors.grey,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (selectedImage == null)
                            Image.asset(
                              "assets/images/user_placeholder.jpg",
                              width: 700,
                              height: 400,
                            )
                          else if (selectedImage != null)
                            Image.file(
                              selectedImage!,
                              width: 700,
                              height: 400,
                            ),
                          ElevatedButton(
                            onPressed: _pickImage,
                            child: const Text('Select Image'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'First Name', // Your label text
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextFormField(
                                controller: _firstNameController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'This field is required.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Last Name', // Your label text
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextFormField(
                                controller: _lastNameController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'This field is required.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Username', // Your label text
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextFormField(
                                controller: _userNameController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'This field is required.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Password', // Your label text
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextFormField(
                                controller: _passwordController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'This field is required.';
                                  }
                                  return null;
                                },
                                obscureText: true, // Hide password characters
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Confirm Password', // Your label text
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextFormField(
                                controller: _confirmPasswordController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'This field is required.';
                                  } else if (value !=
                                      _passwordController.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
                                obscureText: true, // Hide password characters
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email', // Your label text
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextFormField(
                                controller: _emailController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'This field is required.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                    Expanded(
                        child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone number',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextFormField(
                              controller: _phoneNumberController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'This field is required.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Role',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Client',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Address', // Your label text
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextFormField(
                              controller: _addressController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'This field is required.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Postal code', // Your label text
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextFormField(
                              controller: _postalCodeController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'This field is required.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ],
                    )),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                        child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'JMBG', // Your label text
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextFormField(
                              controller: _jmbgController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'This field is required.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        DropdownButtonFormField<City?>(
                          value:
                              selectedCity, // Set the initial value (selectedCity is a City? variable)
                          onChanged: (City? newValue) {
                            setState(() {
                              // Update the selected value when the user makes a selection
                              selectedCity = newValue!;
                              selectedCity!.id = newValue.id;
                            });
                          },
                          items: (cityResult?.result ?? [])
                              .map<DropdownMenuItem<City?>>(
                            (City? city) {
                              if (city != null && city.name != null) {
                                return DropdownMenuItem<City?>(
                                  value: city, // Ensure each value is unique
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
                            labelText: 'City of residence',
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Date of Birth MM-dd-yyyy',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              DateFormat('MM-dd-yyyy')
                                  .format(selectedDate), // Format the date
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _selectDate(
                                  context, newUser.person?.birthDate),
                              child: const Text('Select Date'),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Gender:',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(height: 5.0),
                                DropdownButton<int>(
                                  value: selectedGender,
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      _onGenderChanged(newValue);
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem<int>(
                                      value: 0,
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 1,
                                      child: Text('Female'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ))
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  height: 50,
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () async {
                      await addClient();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.add), // Edit icon
                        SizedBox(width: 10),
                        Text('Add'),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(
                thickness: 2,
                color: Colors.grey,
              ),
            ],
          ))),
    );
  }

  void _onGenderChanged(int newValue) {
    setState(() {
      selectedGender = newValue;
      newUser.person?.gender = newValue;
    });
  }

  Future<void> _selectDate(BuildContext context, DateTime? date) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        date = selectedDate;
      });
    }
  }
}
