import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/application_role.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:propertease_admin/providers/city_provider.dart';
import 'package:provider/provider.dart';

import '../../models/city.dart';
import '../../models/search_result.dart';
import '../../providers/application_role_provider.dart';

class UserEditScreen extends StatefulWidget {
  ApplicationUser? user;
  UserEditScreen({super.key, this.user});
  @override
  State<StatefulWidget> createState() => UserEditScreenState();
}

class UserEditScreenState extends State<UserEditScreen> {
  late ApplicationUser editedUser = ApplicationUser();
  File? selectedImage;
  SearchResult<City>? cityResult;
  SearchResult<ApplicationRole>? roleResult;

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
  final TextEditingController _biographyController = TextEditingController();
  final TextEditingController _qualificationsController =
      TextEditingController();
  final TextEditingController _payController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  int selectedGender = 0; // 0 for Male, 1 for Female

  void _onGenderChanged(int newValue) {
    setState(() {
      selectedGender = newValue;
      widget.user?.person?.gender = newValue;
      print(widget.user?.person?.gender);
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        widget.user?.file = selectedImage;
        widget.user?.person?.profilePhoto = selectedImage?.path;
        widget.user?.person?.profilePhotoThumbnail = selectedImage?.path;
      });
    }
  }

  Future<void> _updateEmployee() async {
    double? parsedPay = double.tryParse(_payController.text);

    editedUser = widget.user!;
    editedUser.person?.gender = widget.user?.person?.gender;
    editedUser.person?.firstName = _firstNameController.text;
    editedUser.person?.lastName = _lastNameController.text;
    editedUser.userName = _userNameController.text;
    editedUser.phoneNumber = _phoneNumberController.text;
    editedUser.person?.address = _addressController.text;
    editedUser.person?.postCode = _postalCodeController.text;
    editedUser.person?.jmbg = _jmbgController.text;
    editedUser.person?.biography = _biographyController.text;
    editedUser.person?.qualifications = _qualificationsController.text;
    editedUser.email = _emailController.text;
    await _userProvider.updateEmployee(editedUser, editedUser.id!);
  }

  Future<void> _fetchRoles() async {
    var roles = await _roleProvider.get();
    setState(() {
      roleResult = roles;
    });
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
    _firstNameController.text = widget.user?.person?.firstName ?? '';
    _lastNameController.text = widget.user?.person?.lastName ?? '';
    _userNameController.text = widget.user?.userName ?? '';
    _emailController.text = widget.user?.email ?? '';
    _phoneNumberController.text = widget.user?.phoneNumber ?? '';
    _addressController.text = widget.user?.person?.address ?? '';
    _postalCodeController.text = widget.user?.person?.postCode ?? '';
    _jmbgController.text = widget.user?.person?.jmbg ?? '';
    _biographyController.text = widget.user?.person?.biography ?? '';
    _qualificationsController.text = widget.user?.person?.qualifications ?? '';
    _payController.text = widget.user?.person?.pay.toString() ?? '0';
    _cityProvider = context.read<CityProvider>();
    _roleProvider = context.read<RoleProvider>();
    _userProvider = context.read<UserProvider>();
    print(widget.user?.userRoles?.length);
    _fetchCities();
    _fetchRoles();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _cityProvider = context.read<CityProvider>();
    _roleProvider = context.read<RoleProvider>();
    _userProvider = context.read<UserProvider>();

    _fetchCities();
    _fetchRoles();
  }

  Widget buildUserRoleRow(ApplicationUser user) {
    if (user.userRoles?[0].role?.roleLevel == 2) {
      return Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.info,
                  color: Colors.blue,
                  size: 24.0,
                ),
                SizedBox(width: 5),
                Text(
                  'Employee information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Position',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              width: 200.0,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              padding: const EdgeInsets.all(10.0),
                              margin: const EdgeInsets.all(10.0),
                              alignment: Alignment.center,
                              child: Text(
                                widget.user?.person?.position == 0
                                    ? 'Client'
                                    : widget.user?.person?.position == 1
                                        ? 'Renter'
                                        : '',
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Qualifications',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              width: 200.0,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              padding: const EdgeInsets.all(10.0),
                              margin: const EdgeInsets.all(10.0),
                              alignment: Alignment.center,
                              child: TextFormField(
                                controller: _qualificationsController,
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Enter additional information',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Date of employment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          "${widget.user?.person?.dateOfEmployment?.toLocal()}"
                              .split(' ')[0],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _selectDate(
                              context, widget.user?.person?.dateOfEmployment),
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Work experience',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Checkbox(
                      value: widget.user?.person?.workExperience == true,
                      onChanged: (value) {
                        setState(() {
                          widget.user?.person?.workExperience = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 200.0,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      margin: const EdgeInsets.all(10.0),
                      alignment: Alignment.center,
                      child: TextFormField(
                        controller: _payController,
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Biography',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 800.0,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      margin: const EdgeInsets.all(10.0),
                      alignment: Alignment.center,
                      child: TextFormField(
                        maxLines: 35,
                        minLines: 8,
                        controller: _biographyController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: 'Enter additional information',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // User has no role, return an empty Row
      return const SizedBox.shrink();
    }
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
      appBar: AppBar(title: const Text('User edit screen')),
      body: SingleChildScrollView(
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selectedImage == null)
                        Image.network(
                          "https://localhost:44340${widget.user!.person?.profilePhoto}",
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
                          'Phone number', // Your label text
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextFormField(
                          controller: _phoneNumberController,
                        ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      value: widget.user?.userRoles?.isNotEmpty == true
                          ? widget.user!.userRoles![0].role?.id.toString()
                          : null, // Set the initial value (if userRoles is not empty)
                      onChanged: (String? newValue) {
                        setState(() {
                          if (widget.user?.userRoles?.isNotEmpty == true) {
                            // Find the corresponding ApplicationRole object
                            widget.user!.userRoles![0].role =
                                roleResult?.result.firstWhere(
                              (role) => role.id.toString() == newValue,
                              orElse: () =>
                                  ApplicationRole(), // Provide a default value
                            );
                          }
                        });
                      },
                      items: (roleResult?.result ?? [])
                          .map<DropdownMenuItem<String>>(
                              (ApplicationRole? role) {
                        if (role != null && role.name != null) {
                          return DropdownMenuItem<String>(
                            value: role.id.toString(),
                            child: Text(role.name!),
                          );
                        } else {
                          return const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Undefined'),
                          );
                        }
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Role',
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
                        ),
                      ],
                    ),
                    DropdownButtonFormField<City?>(
                      value: widget.user?.person
                          ?.placeOfResidence, // Set the initial value (selectedCity is a City? variable)
                      onChanged: (City? newValue) {
                        setState(() {
                          // Update the selected value when the user makes a selection
                          widget.user?.person?.placeOfResidence = newValue;
                          widget.user?.person?.placeOfResidence?.id =
                              newValue?.id;
                          widget.user?.person?.placeOfResidenceId =
                              newValue?.id;
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
                          'Date of Birth',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          "${widget.user?.person?.birthDate?.toLocal()}"
                              .split(' ')[0],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton(
                          onPressed: () => _selectDate(
                              context, widget.user?.person?.birthDate),
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
                              value: widget.user?.person?.gender,
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
          buildUserRoleRow(widget.user!),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              height: 50,
              width: 90,
              child: ElevatedButton(
                onPressed: () async {
                  await _updateEmployee();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit), // Edit icon
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
