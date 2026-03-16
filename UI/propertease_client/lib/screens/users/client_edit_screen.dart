import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/screens/users/change_password_screen.dart';
import 'package:provider/provider.dart';

import '../../models/application_user.dart';
import '../../models/city.dart';
import '../../providers/application_user_provider.dart';
import '../../widgets/country_city_selector.dart';

class UserEditScreen extends StatefulWidget {
  final ApplicationUser? user;
  const UserEditScreen({super.key, this.user});
  @override
  State<StatefulWidget> createState() => UserEditScreenState();
}

class UserEditScreenState extends State<UserEditScreen> {
  late ApplicationUser editedUser;
  File? selectedImage;
  City? selectedCity;
  late int selectedGender;
  final _formKey = GlobalKey<FormState>();

  late UserProvider _userProvider;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _jmbgController = TextEditingController();
  String? profilePhoto;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    editedUser = widget.user!;
    _userProvider = context.read<UserProvider>();

    _firstNameController.text = widget.user?.person?.firstName ?? '';
    _lastNameController.text = widget.user?.person?.lastName ?? '';
    _userNameController.text = widget.user?.userName ?? '';
    _emailController.text = widget.user?.email ?? '';
    _phoneNumberController.text = widget.user?.phoneNumber ?? '';
    _addressController.text = widget.user?.person?.address ?? '';
    _postalCodeController.text = widget.user?.person?.postCode ?? '';
    _jmbgController.text = widget.user?.person?.jmbg ?? '';
    selectedGender = widget.user?.person?.gender ?? 0;
    selectedCity = widget.user?.person?.placeOfResidence;
    if (selectedCity != null) selectedCity!.id = widget.user?.person?.placeOfResidenceId;
    selectedDate = widget.user?.person?.birthDate ?? DateTime(2000);
    profilePhoto = editedUser.person?.profilePhotoBytes;
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
    if (!_formKey.currentState!.validate()) return;

    editedUser.person?.gender = selectedGender;
    editedUser.person?.firstName = _firstNameController.text;
    editedUser.person?.lastName = _lastNameController.text;
    editedUser.person?.birthDate = selectedDate;
    editedUser.userName = _userNameController.text;
    editedUser.email = _emailController.text;
    editedUser.phoneNumber = _phoneNumberController.text;
    editedUser.person?.address = _addressController.text;
    editedUser.person?.postCode = _postalCodeController.text;
    editedUser.person?.jmbg = _jmbgController.text;
    editedUser.person?.placeOfResidenceId = selectedCity?.id;

    await _userProvider.updateClient(editedUser, editedUser.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'User ${editedUser.person?.firstName} ${editedUser.person?.lastName} updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<DateTime?> _selectDate(DateTime? current) => showDatePicker(
        context: context,
        initialDate: current ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2101),
      );

  ImageProvider? get _avatarImage {
    if (selectedImage != null) return FileImage(selectedImage!);
    if (profilePhoto != null && profilePhoto!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(profilePhoto!));
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarImage;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ────────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.shade50,
                            backgroundImage: avatar,
                            child: avatar == null
                                ? Icon(Icons.person,
                                    size: 64, color: Colors.blue.shade200)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.photo_camera,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Tap to change photo',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Personal details ──────────────────────────────────────────
              _SectionCard(
                title: 'Personal Details',
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: _field('First Name', _firstNameController)),
                      const SizedBox(width: 16),
                      Expanded(child: _field('Last Name', _lastNameController)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _field('JMBG', _jmbgController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required.';
                            if (!RegExp(r'^\d{13}$').hasMatch(v)) {
                              return 'Must be exactly 13 digits.';
                            }
                            return null;
                          })),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await _selectDate(selectedDate);
                            if (d != null) setState(() => selectedDate = d);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                                DateFormat('dd.MM.yyyy').format(selectedDate)),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedGender,
                      decoration: const InputDecoration(
                          labelText: 'Gender', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Male')),
                        DropdownMenuItem(value: 1, child: Text('Female')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            selectedGender = v;
                            editedUser.person?.gender = v;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CountryCitySelector(
                      initialCity: selectedCity,
                      onCityChanged: (city) {
                        setState(() => selectedCity = city);
                        editedUser.person?.placeOfResidenceId = city?.id;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _field('Address', _addressController)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _field('Postal Code', _postalCodeController)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Account details ───────────────────────────────────────────
              _SectionCard(
                title: 'Account Details',
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                          child: _field('Username', _userNameController,
                              validator: (v) {
                        if (v == null || v.isEmpty) return 'Required.';
                        if (v.length < 3) return 'At least 3 characters.';
                        if (!RegExp(r'^[a-zA-Z0-9_.\-]+$').hasMatch(v)) {
                          return 'Only letters, numbers and _.-';
                        }
                        return null;
                      })),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _field('Email', _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                        if (v == null || v.isEmpty) return 'Required.';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      })),
                    ]),
                    const SizedBox(height: 16),
                    _field('Phone Number', _phoneNumberController,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                      if (v == null || v.isEmpty) return 'Required.';
                      if (!RegExp(r'^\+?[0-9\s\-]{7,15}$').hasMatch(v)) {
                        return 'Enter a valid phone number.';
                      }
                      return null;
                    }),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ChangePasswordScreen(user: widget.user),
                          ),
                        ),
                        icon: const Icon(Icons.lock_outline, size: 16),
                        label: const Text('Change Password'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _updateClient,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _field(
    String label,
    TextEditingController ctrl, {
    bool required = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator ??
          (required
              ? (v) => (v == null || v.isEmpty) ? 'Required.' : null
              : null),
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
