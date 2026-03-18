import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/models/city.dart';
import 'package:propertease_admin/models/person.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../widgets/country_city_selector.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late UserProvider _userProvider;

  ApplicationUser? _user;
  File? _selectedImage;
  bool _loading = true;
  String? _loadError;

  City? _selectedCity;
  int _selectedGender = 0;
  DateTime _selectedDate = DateTime(2000);

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _jmbgController = TextEditingController();

  // password change
  final _pwFormKey = GlobalKey<FormState>();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _pwObscureCurrent = true;
  bool _pwObscureNew = true;
  bool _pwObscureConfirm = true;


  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _loadUser();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _jmbgController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userProvider.getById(Authorization.userId!);
      if (mounted) {
        setState(() {
          _user = user;
          _firstNameController.text = user.person?.firstName ?? '';
          _lastNameController.text = user.person?.lastName ?? '';
          _userNameController.text = user.userName ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = user.phoneNumber ?? '';
          _addressController.text = user.person?.address ?? '';
          _postalCodeController.text = user.person?.postCode ?? '';
          _jmbgController.text = user.person?.jmbg ?? '';
          _selectedGender = user.person?.gender ?? 0;
          _selectedDate = user.person?.birthDate ?? DateTime(2000);
          _selectedCity = user.person?.placeOfResidence;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _user?.file = _selectedImage;
        _user?.person?.profilePhoto = picked.path;
        _user?.person?.profilePhotoThumbnail = picked.path;
      });
    }
  }

  Future<void> _save() async {
    if (_user == null) return;
    if (!_formKey.currentState!.validate()) return;

    _user!.person ??= Person();
    _user!.person!.firstName = _firstNameController.text.trim();
    _user!.person!.lastName = _lastNameController.text.trim();
    _user!.userName = _userNameController.text.trim();
    _user!.email = _emailController.text.trim();
    _user!.phoneNumber = _phoneController.text.trim();
    _user!.person!.address = _addressController.text.trim();
    _user!.person!.postCode = _postalCodeController.text.trim();
    _user!.person!.jmbg = _jmbgController.text.trim();
    _user!.person!.gender = _selectedGender;
    _user!.person!.birthDate = _selectedDate;
    _user!.person!.placeOfResidenceId = _selectedCity?.id;

    try {
      await _userProvider.updateProfile(_user!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
      return;
    }

    try {
      final refreshed = await _userProvider.getById(Authorization.userId!);
      Authorization.profilePhoto = refreshed.person?.profilePhoto;
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil uspješno ažuriran'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _changePassword() async {
    if (!_pwFormKey.currentState!.validate()) return;

    try {
      await _userProvider.changePassword(
        Authorization.userId!,
        _currentPwController.text,
        _newPwController.text,
      );
      _currentPwController.clear();
      _newPwController.clear();
      _confirmPwController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lozinka uspješno promijenjena'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
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
      appBar: AppBar(
        title: const Text('Moj profil'),
        actions: [
          if (!_loading)
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Spremi', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Greška pri učitavanju profila:\n$_loadError',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Avatar ─────────────────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 64,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: _selectedImage != null
                                          ? FileImage(_selectedImage!)
                                              as ImageProvider
                                          : (_user?.person?.profilePhoto !=
                                                      null &&
                                                  _user!.person!.profilePhoto!
                                                      .isNotEmpty)
                                              ? NetworkImage(
                                                  '${AppConfig.serverBase}${_user!.person!.profilePhoto}')
                                              : null,
                                      child: (_selectedImage == null &&
                                              (_user?.person?.profilePhoto ==
                                                      null ||
                                                  _user!.person!.profilePhoto!
                                                      .isEmpty))
                                          ? const Icon(Icons.person,
                                              size: 64, color: Colors.grey)
                                          : null,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tapnite za promjenu slike',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Lični podaci ───────────────────────────────────────
                        _buildCard(
                          title: 'Lični podaci',
                          icon: Icons.person,
                          children: [
                            Row(children: [
                              Expanded(
                                child: _field(
                                  controller: _firstNameController,
                                  label: 'Ime',
                                  icon: Icons.badge,
                                  required: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(
                                  controller: _lastNameController,
                                  label: 'Prezime',
                                  icon: Icons.badge_outlined,
                                  required: true,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                child: _field(
                                  controller: _jmbgController,
                                  label: 'JMBG',
                                  icon: Icons.fingerprint,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Obavezno polje';
                                    if (!RegExp(r'^\d{13}$').hasMatch(v)) {
                                      return 'JMBG mora imati 13 cifara';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final d = await _selectDate(_selectedDate);
                                    if (d != null) setState(() => _selectedDate = d);
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Datum rođenja',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                        DateFormat('dd.MM.yyyy').format(_selectedDate)),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              value: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Spol',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.wc),
                              ),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Muški')),
                                DropdownMenuItem(value: 1, child: Text('Ženski')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedGender = v);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Kontakt i lokacija ─────────────────────────────────
                        _buildCard(
                          title: 'Kontakt i lokacija',
                          icon: Icons.contact_phone,
                          children: [
                            _field(
                              controller: _emailController,
                              label: 'E-mail',
                              icon: Icons.email,
                              required: true,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: _phoneController,
                              label: 'Broj telefona',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            CountryCitySelector(
                              initialCity: _selectedCity,
                              onCityChanged: (city) {
                                _selectedCity = city;
                                _user?.person?.placeOfResidenceId = city?.id;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                child: _field(
                                  controller: _addressController,
                                  label: 'Adresa',
                                  icon: Icons.home,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(
                                  controller: _postalCodeController,
                                  label: 'Poštanski broj',
                                  icon: Icons.markunread_mailbox_outlined,
                                ),
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Podaci naloga ──────────────────────────────────────
                        _buildCard(
                          title: 'Podaci naloga',
                          icon: Icons.manage_accounts,
                          children: [
                            _field(
                              controller: _userNameController,
                              label: 'Korisničko ime',
                              icon: Icons.alternate_email,
                              required: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save),
                            label: const Text('Spremi izmjene'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Promjena lozinke ───────────────────────────────────
                        Form(
                          key: _pwFormKey,
                          child: _buildCard(
                            title: 'Promjena lozinke',
                            icon: Icons.lock_outline,
                            children: [
                              _pwField(
                                controller: _currentPwController,
                                label: 'Trenutna lozinka',
                                obscure: _pwObscureCurrent,
                                onToggle: () => setState(
                                    () => _pwObscureCurrent = !_pwObscureCurrent),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Unesite trenutnu lozinku'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _pwField(
                                controller: _newPwController,
                                label: 'Nova lozinka',
                                obscure: _pwObscureNew,
                                onToggle: () =>
                                    setState(() => _pwObscureNew = !_pwObscureNew),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Unesite novu lozinku';
                                  if (v.length < 8) return 'Lozinka mora imati najmanje 8 znakova';
                                  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Lozinka mora sadržavati veliko slovo';
                                  if (!RegExp(r'\d').hasMatch(v)) return 'Lozinka mora sadržavati broj';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _pwField(
                                controller: _confirmPwController,
                                label: 'Potvrdi novu lozinku',
                                obscure: _pwObscureConfirm,
                                onToggle: () => setState(
                                    () => _pwObscureConfirm = !_pwObscureConfirm),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Unesite potvrdu lozinke';
                                  if (v != _newPwController.text) return 'Lozinke se ne podudaraju';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: _changePassword,
                                  icon: const Icon(Icons.lock_reset),
                                  label: const Text('Promijeni lozinku'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
            Row(children: [
              Icon(icon, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Obavezno polje' : null
              : null),
    );
  }

  Widget _pwField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
