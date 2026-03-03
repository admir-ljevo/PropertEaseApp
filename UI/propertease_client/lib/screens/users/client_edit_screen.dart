import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/screens/users/change_password_screen.dart';

import 'package:provider/provider.dart';

import '../../models/application_user.dart';
import '../../models/city.dart';
import '../../models/search_result.dart';
import '../../providers/application_user_provider.dart';
import '../../providers/city_provider.dart';

class UserEditScreen extends StatefulWidget {
  ApplicationUser? user;
  UserEditScreen({super.key, this.user});
  @override
  State<StatefulWidget> createState() => UserEditScreenState();
}

class UserEditScreenState extends State<UserEditScreen> {
  late ApplicationUser editedUser;
  File? selectedImage;
  SearchResult<City>? cityResult;
  City? selectedCity;
  late int selectedGender;
  final _formKey = GlobalKey<FormState>();

  late CityProvider _cityProvider;
  late UserProvider _userProvider;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _jmbgController = TextEditingController();
  final TextEditingController _biographyController = TextEditingController();
  final TextEditingController _qualificationsController =
      TextEditingController();
  final TextEditingController _payController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? profilePhoto;
  late DateTime selectedDate;
  DateTime selectedEmploymentDate = DateTime.now();
  // 0 for Male, 1 for Female
  int selectedRole = 0;
  void _onGenderChanged(int newValue) {
    setState(() {
      selectedGender = newValue;
      widget.user?.person?.gender = newValue;
      print(widget.user?.person?.gender);
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);

        editedUser.file = File(pickedFile.path);
        editedUser.person?.profilePhoto = selectedImage?.path;
        editedUser.person?.profilePhotoThumbnail = selectedImage?.path;
      });
    }
  }

  Future<void> _updateClient() async {
    editedUser.person?.gender = widget.user?.person?.gender;
    editedUser.person?.firstName = _firstNameController.text;
    editedUser.person?.lastName = _lastNameController.text;
    editedUser.person?.birthDate = selectedDate;
    editedUser.userName = _userNameController.text;
    editedUser.phoneNumber = _phoneNumberController.text;
    editedUser.person?.address = _addressController.text;
    editedUser.person?.postCode = _postalCodeController.text;
    editedUser.person?.jmbg = _jmbgController.text;

    editedUser.person?.placeOfResidenceId = selectedCity?.id;
    if (_formKey.currentState!.validate()) {
      if (widget.user?.userRoles?[0].role?.id == 4) {
        await _userProvider.updateClient(editedUser, editedUser.id!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'User ${editedUser.person?.firstName} ${editedUser.person?.lastName} edited successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  String formatBirthDate(DateTime? birthDate) {
    if (birthDate != null) {
      final dateFormat = DateFormat('MM-dd-yyyy');
      return dateFormat.format(birthDate);
    } else {
      return 'N/A';
    }
  }

  @override
  void initState() {
    super.initState();
    editedUser = widget.user!;

    _firstNameController.text = widget.user?.person?.firstName ?? '';
    _lastNameController.text = widget.user?.person?.lastName ?? '';
    _userNameController.text = widget.user?.userName ?? '';
    _emailController.text = widget.user?.email ?? '';
    _phoneNumberController.text = widget.user?.phoneNumber ?? '';
    _addressController.text = widget.user?.person?.address ?? '';
    _postalCodeController.text = widget.user?.person?.postCode ?? '';
    _jmbgController.text = widget.user?.person?.jmbg ?? '';
    selectedGender = widget.user!.person!.gender!;
    _cityProvider = context.read<CityProvider>();
    _userProvider = context.read<UserProvider>();
    selectedCity = widget.user!.person!.placeOfResidence;
    selectedCity!.id = widget.user!.person!.placeOfResidenceId;
    selectedDate = widget.user!.person!.birthDate!;
    profilePhoto = editedUser.person!.profilePhotoBytes;
    print(widget.user?.userRoles?.length);
    _fetchCities();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    editedUser = widget.user!;

    _cityProvider = context.read<CityProvider>();
    _userProvider = context.read<UserProvider>();
    _firstNameController.text = widget.user?.person?.firstName ?? '';
    _lastNameController.text = widget.user?.person?.lastName ?? '';
    _userNameController.text = widget.user?.userName ?? '';
    _emailController.text = widget.user?.email ?? '';
    _phoneNumberController.text = widget.user?.phoneNumber ?? '';
    _addressController.text = widget.user?.person?.address ?? '';
    _postalCodeController.text = widget.user?.person?.postCode ?? '';
    _jmbgController.text = widget.user?.person?.jmbg ?? '';
    selectedGender = widget.user!.person!.gender!;
    selectedCity = widget.user!.person!.placeOfResidence;
    selectedCity!.id = widget.user!.person!.placeOfResidenceId;
    profilePhoto = editedUser.person!.profilePhotoBytes;

    selectedDate = widget.user!.person!.birthDate!;
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    var cities = await _cityProvider.get();
    setState(() {
      cityResult = cities;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile details"),
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
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 34.0,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Edit profile',
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
                child: Column(
                  children: [
                    if (selectedImage == null)
                      Image.memory(
                        base64Decode(profilePhoto!),
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
                      onPressed: () {
                        setState(() {
                          _pickImage();
                        });
                      },
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
              Column(
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChangePasswordScreen(
                              user: widget.user,
                            ),
                          ),
                        );
                      },
                      child: Text("Change your password"))
                ],
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
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Last Name',
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
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Username',
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address',
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Postal code',
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JMBG',
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
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<City?>(
                  value: selectedCity,
                  onChanged: (City? newValue) {
                    setState(() {
                      selectedCity = newValue!;
                      selectedCity!.id = newValue.id;
                    });
                  },
                  items: (cityResult?.result ?? [])
                      .map<DropdownMenuItem<City?>>((City? city) {
                    if (city != null && city.name != null) {
                      return DropdownMenuItem<City?>(
                        value: city,
                        child: Text(city.name!),
                      );
                    } else {
                      return const DropdownMenuItem<City?>(
                        value: null,
                        child: Text(
                          'Undefined',
                        ),
                      );
                    }
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'City of residence',
                  ),
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
                    const SizedBox(
                      height: 5.0,
                    ),
                    Text(
                      DateFormat('MM-dd-yyyy').format(selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        DateTime? newDate =
                            await _selectDate(context, selectedDate);
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
                    const Text(
                      'Gender:',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 5.0),
                    DropdownButton<int>(
                      value: selectedGender,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _onGenderChanged(newValue);
                          });
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
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  height: 50,
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateClient();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 20),
                        Text('Edit'),
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
          ),
        ),
      ),
    );
  }
}
