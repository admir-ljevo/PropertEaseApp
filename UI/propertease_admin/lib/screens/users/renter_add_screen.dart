import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/application_user.dart';
import '../../models/city.dart';
import '../../models/person.dart';
import '../../models/search_result.dart';
import '../../providers/application_user_provider.dart';
import '../../providers/city_provider.dart';

class RenterAddScreen extends StatefulWidget {
  const RenterAddScreen({super.key});

  @override
  State<StatefulWidget> createState() => RenterAddScreenState();
}

class RenterAddScreenState extends State<RenterAddScreen> {
  late ApplicationUser newUser = ApplicationUser();
  File? selectedImage;
  City? selectedCity;
  SearchResult<City>? cityResult;
  final _formKey = GlobalKey<FormState>();

  late CityProvider _cityProvider;
  late UserProvider _userProvider;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _jmbgController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _citizenShipController = TextEditingController();

  int selectedGender = 0;
  DateTime selectedDate = DateTime.now();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _cityProvider = context.read<CityProvider>();
    _userProvider = context.read<UserProvider>();
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    final cities = await _cityProvider.get();
    setState(() {
      cityResult = cities;
      if (cities.result.isNotEmpty) selectedCity = cities.result[0];
    });
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

  Future<void> _addRenter() async {
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
    newUser.person?.placeOfResidenceId = selectedCity!.id;
    newUser.person?.citizenship = _citizenShipController.text;
    newUser.person?.nationality = _nationalityController.text;
    await _userProvider.addEmployee(newUser, _passwordController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Izdavač ${newUser.person?.firstName} ${newUser.person?.lastName} uspješno dodan'),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).pop();
    }
  }

  Future<DateTime?> _selectDate(DateTime? current) => showDatePicker(
        context: context,
        initialDate: current ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2101),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj izdavača')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ─────────────────────────────────────────────────────
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
                            backgroundImage: selectedImage != null
                                ? FileImage(selectedImage!) as ImageProvider
                                : null,
                            child: selectedImage == null
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
                    Text('Tapni za odabir fotografije',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Lični podaci ────────────────────────────────────────────────
              _SectionCard(
                title: 'Lični podaci',
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: _field('Ime', _firstNameController)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _field('Prezime', _lastNameController)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _field('JMBG', _jmbgController)),
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
                              labelText: 'Datum rođenja',
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
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedGender,
                          decoration: const InputDecoration(
                              labelText: 'Spol',
                              border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Muški')),
                            DropdownMenuItem(value: 1, child: Text('Ženski')),
                          ],
                          onChanged: (v) =>
                              setState(() => selectedGender = v ?? 0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<City?>(
                          value: selectedCity,
                          decoration: const InputDecoration(
                              labelText: 'Grad',
                              border: OutlineInputBorder()),
                          items: (cityResult?.result ?? [])
                              .map<DropdownMenuItem<City?>>(
                                  (c) => DropdownMenuItem<City?>(
                                      value: c,
                                      child: Text(c.name ?? '')))
                              .toList(),
                          onChanged: (v) => setState(() {
                            selectedCity = v;
                            selectedCity?.id = v?.id;
                          }),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: _field('Adresa', _addressController)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _field(
                              'Poštanski broj', _postalCodeController)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Podaci naloga ───────────────────────────────────────────────
              _SectionCard(
                title: 'Podaci naloga',
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                          child: _field(
                              'Korisničko ime', _userNameController)),
                      const SizedBox(width: 16),
                      Expanded(child: _field('Email', _emailController)),
                    ]),
                    const SizedBox(height: 16),
                    _field('Telefon', _phoneNumberController),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Obavezno polje'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Lozinka',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Obavezno polje';
                            }
                            if (v != _passwordController.text) {
                              return 'Lozinke se ne poklapaju';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Potvrdi lozinku',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        avatar: const Icon(Icons.badge_outlined, size: 16),
                        label: const Text('Uloga: Izdavač'),
                        backgroundColor: Colors.green.shade50,
                        labelStyle: TextStyle(
                            color: Colors.green.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _addRenter,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Dodaj izdavača'),
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

  TextFormField _field(String label, TextEditingController ctrl,
      {bool required = true}) {
    return TextFormField(
      controller: ctrl,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Obavezno polje' : null
          : null,
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
