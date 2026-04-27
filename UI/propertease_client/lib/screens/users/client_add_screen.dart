import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import 'package:propertease_client/models/application_user.dart';
import 'package:propertease_client/models/city.dart';
import 'package:propertease_client/models/person.dart';
import 'package:propertease_client/providers/application_user_provider.dart';
import 'package:propertease_client/widgets/country_city_selector.dart';


class ClientAddScreen extends StatefulWidget {
  const ClientAddScreen({super.key});

  @override
  State<StatefulWidget> createState() => ClientAddScreenState();
}

class ClientAddScreenState extends State<ClientAddScreen> {
  late ApplicationUser newUser = ApplicationUser();
  File? selectedImage;
  City? selectedCity;
  final _formKey = GlobalKey<FormState>();
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

  int selectedGender = 0;
  DateTime selectedDate = DateTime.now();

  Future<void> addClient() async {
    if (!_formKey.currentState!.validate()) return;

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
    newUser.person?.birthDate = selectedDate;
    newUser.person?.placeOfResidenceId = selectedCity?.id;

    await _userProvider.addClient(newUser, _passwordController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Client ${newUser.person?.firstName} ${newUser.person?.lastName} added successfully'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

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

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile registration"),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
              const Divider(thickness: 2, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (selectedImage == null)
                      Image.asset(
                        "assets/images/user_placeholder.jpg",
                        width: 700,
                        height: 400,
                      ),
                    if (selectedImage != null)
                      Image.file(
                        selectedImage!,
                        width: 700,
                        height: 400,
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.image),
                          SizedBox(width: 8),
                          Text('Select Image'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'First Name',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            TextFormField(
                              controller: _firstNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'This field is required.';
                                }
                                if (value.length < 2) {
                                  return 'At least 2 characters.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Last Name',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          TextFormField(
                            controller: _lastNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'This field is required.';
                              }
                              if (value.length < 2) {
                                return 'At least 2 characters.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Username',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextFormField(
                      controller: _userNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        if (value.length < 3) {
                          return 'At least 3 characters.';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_.\-]+$').hasMatch(value)) {
                          return 'Only letters, numbers and _.-';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Password',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        if (value.length < 6) {
                          return 'At least 6 characters.';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Must contain at least one uppercase letter.';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Must contain at least one number.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Confirm Password',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phone number',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        if (!RegExp(r'^\+?[0-9\s\-]{7,15}$').hasMatch(value)) {
                          return 'Enter a valid phone number.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Role',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Client', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Address',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextFormField(
                      controller: _addressController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Postal code',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextFormField(
                      controller: _postalCodeController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('JMBG',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextFormField(
                      controller: _jmbgController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        if (!RegExp(r'^\d{13}$').hasMatch(value)) {
                          return 'JMBG must be exactly 13 digits.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CountryCitySelector(
                  onCityChanged: (city) => setState(() => selectedCity = city),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Date of Birth MM-dd-yyyy',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      DateFormat('MM-dd-yyyy').format(selectedDate),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final newDate = await _selectDate(context, selectedDate);
                        if (newDate != null) {
                          setState(() {
                            selectedDate = newDate;
                          });
                        }
                      },
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text('Gender:', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 5.0),
                    DropdownButton<int>(
                      value: selectedGender,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          _onGenderChanged(newValue);
                        }
                      },
                      items: const [
                        DropdownMenuItem<int>(value: 0, child: Text('Male')),
                        DropdownMenuItem<int>(value: 1, child: Text('Female')),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  height: 50,
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () async {
                      await addClient();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 20),
                        Text('Add'),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(thickness: 2, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _onGenderChanged(int newValue) {
    setState(() {
      selectedGender = newValue;
      newUser.person?.gender = newValue;
    });
  }

  Future<DateTime?> _selectDate(BuildContext context, DateTime? date) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    return picked;
  }
}
