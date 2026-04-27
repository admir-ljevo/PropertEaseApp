import 'dart:io';

import 'package:flutter/material.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/application_role.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/providers/application_role_provider.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:propertease_admin/utils/validators.dart';
import 'package:provider/provider.dart';

import '../../widgets/country_city_selector.dart';

class UserEditScreen extends StatefulWidget {
  // ignore: must_be_immutable
  ApplicationUser? user;
  UserEditScreen({super.key, this.user});

  @override
  State<StatefulWidget> createState() => UserEditScreenState();
}

class UserEditScreenState extends State<UserEditScreen> {
  late ApplicationUser editedUser = ApplicationUser();
  File? selectedImage;

  final _formKey = GlobalKey<FormState>();
  final _pwFormKey = GlobalKey<FormState>();

  late UserProvider _userProvider;
  late RoleProvider _roleProvider;

  List<Map<String, dynamic>> _userRoles = [];
  List<ApplicationRole> _allRoles = [];
  ApplicationRole? _selectedRole;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _jmbgController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  // Password change (admin-initiated — no old password required)
  bool _changePassword = false;
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _roleProvider = context.read<RoleProvider>();

    _firstNameController.text = widget.user?.person?.firstName ?? '';
    _lastNameController.text = widget.user?.person?.lastName ?? '';
    _userNameController.text = widget.user?.userName ?? '';
    _emailController.text = widget.user?.email ?? '';
    _phoneNumberController.text = widget.user?.phoneNumber ?? '';
    _addressController.text = widget.user?.person?.address ?? '';
    _postalCodeController.text = widget.user?.person?.postCode ?? '';
    _jmbgController.text = widget.user?.person?.jmbg ?? '';
    selectedDate = widget.user?.person?.birthDate ?? DateTime.now();

    _loadRoles();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _jmbgController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final results = await Future.wait([
        _userProvider.getUserRoles(widget.user!.id!),
        _roleProvider.get(),
      ]);
      if (mounted) {
        setState(() {
          _userRoles = results[0] as List<Map<String, dynamic>>;
          _allRoles = (results[1] as dynamic).result as List<ApplicationRole>;
          _selectedRole = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Greška pri učitavanju uloga: $e'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _assignRole() async {
    if (_selectedRole == null) return;
    try {
      await _userProvider.assignRole(widget.user!.id!, _selectedRole!.id!);
      await _loadRoles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeRole(Map<String, dynamic> userRole) async {
    final name = userRole['role']?['name'] ?? 'uloga';
    try {
      await _userProvider.removeUserRole(
          widget.user!.id!, userRole['roleId'] as int);
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Uloga "$name" uklonjena'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Greška pri uklanjanju uloge: $e'),
              backgroundColor: Colors.red),
        );
      }
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
    final profileValid = _formKey.currentState!.validate();
    final pwValid =
        !_changePassword || _pwFormKey.currentState!.validate();

    if (!profileValid || !pwValid) return;

    editedUser = widget.user!;
    editedUser.person?.gender = widget.user?.person?.gender;
    editedUser.person?.firstName = _firstNameController.text.trim();
    editedUser.person?.lastName = _lastNameController.text.trim();
    editedUser.userName = _userNameController.text.trim();
    editedUser.phoneNumber = _phoneNumberController.text.trim();
    editedUser.person?.address = _addressController.text.trim();
    editedUser.person?.postCode = _postalCodeController.text.trim();
    editedUser.person?.jmbg = _jmbgController.text.trim();
    editedUser.email = _emailController.text.trim();

    try {
      final roleName = widget.user?.userRoles?.isNotEmpty == true
          ? widget.user!.userRoles![0].role?.name
          : null;

      if (roleName == 'Client') {
        await _userProvider.updateClient(editedUser, editedUser.id!);
      } else {
        await _userProvider.updateEmployee(editedUser, editedUser.id!);
      }

      // Admin password reset (no old password required)
      if (_changePassword) {
        await _userProvider.adminResetPassword(
            widget.user!.id!, _newPwController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Korisnik ${editedUser.person?.firstName} ${editedUser.person?.lastName} uspješno izmijenjen'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Greška pri izmjeni: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<DateTime?> _selectDate(DateTime? current) => showDatePicker(
        context: context,
        initialDate: current ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2101),
      );

  String get _roleName => _userRoles.isNotEmpty
      ? (_userRoles[0]['role']?['name'] ?? '—')
      : '—';

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.user?.person?.profilePhoto != null
        ? '${AppConfig.serverBase}${widget.user!.person!.profilePhoto}'
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Izmjeni korisnika')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ───────────────────────────────────────────────────────
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
                              ? FileImage(selectedImage!)
                              : photoUrl != null
                                  ? NetworkImage(photoUrl) as ImageProvider
                                  : null,
                          child: selectedImage == null && photoUrl == null
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
                  Text('Tapni za promjenu fotografije',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Profile form ─────────────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // ── Lični podaci ──────────────────────────────────────────
                  _SectionCard(
                    title: 'Lični podaci',
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(
                              child: _field('Ime', _firstNameController,
                                  validator: (v) =>
                                      AppValidators.name(v, label: 'Ime'))),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _field(
                                  'Prezime', _lastNameController,
                                  validator: (v) => AppValidators.name(v,
                                      label: 'Prezime'))),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: _field('JMBG', _jmbgController,
                                  validator: (v) =>
                                      AppValidators.jmbg(v, required: false))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await _selectDate(selectedDate);
                                if (d != null) {
                                  setState(() {
                                    selectedDate = d;
                                    widget.user?.person?.birthDate = d;
                                  });
                                }
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
                              value: widget.user?.person?.gender,
                              decoration: const InputDecoration(
                                  labelText: 'Spol',
                                  border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(
                                    value: 0, child: Text('Muški')),
                                DropdownMenuItem(
                                    value: 1, child: Text('Ženski')),
                              ],
                              onChanged: (v) => setState(
                                  () => widget.user?.person?.gender = v),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        CountryCitySelector(
                          initialCity: widget.user?.person?.placeOfResidence,
                          onCityChanged: (c) {
                            widget.user?.person?.placeOfResidence = c;
                            widget.user?.person?.placeOfResidenceId = c?.id;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child:
                                  _field('Adresa', _addressController)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _field(
                                  'Poštanski broj', _postalCodeController)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Podaci naloga ─────────────────────────────────────────
                  _SectionCard(
                    title: 'Podaci naloga',
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(
                              child: _field(
                                  'Korisničko ime', _userNameController,
                                  validator: AppValidators.username)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _field('Email', _emailController,
                                  validator: AppValidators.email)),
                        ]),
                        const SizedBox(height: 16),
                        _field('Telefon', _phoneNumberController,
                            validator: AppValidators.phone),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            avatar: const Icon(Icons.verified_user_outlined,
                                size: 16),
                            label: Text('Uloga: $_roleName'),
                            backgroundColor: Colors.blue.shade50,
                            labelStyle: TextStyle(
                                color: Colors.blue.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Uloge ────────────────────────────────────────────────────────
            if (widget.user?.userRoles?.isEmpty != false ||
                widget.user?.userRoles?[0].role?.roleLevel != 1)
              _SectionCard(
                title: 'Uloge',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _userRoles
                          .map((ur) => Chip(
                                label: Text(ur['role']?['name'] ?? ''),
                                deleteIcon:
                                    const Icon(Icons.close, size: 16),
                                onDeleted: () => _removeRole(ur),
                                backgroundColor: Colors.blue.shade50,
                                labelStyle: TextStyle(
                                    color: Colors.blue.shade700, fontSize: 12),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ApplicationRole>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Dodjeli ulogu',
                              border: OutlineInputBorder(),
                            ),
                            items: _allRoles
                                .where((r) => !_userRoles
                                    .any((ur) => ur['roleId'] == r.id))
                                .map((r) => DropdownMenuItem(
                                    value: r, child: Text(r.name ?? '')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedRole = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed:
                              _selectedRole != null ? _assignRole : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Dodjeli'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Promjena lozinke (admin — bez stare lozinke) ─────────────────
            _SectionCard(
              title: 'Lozinka',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _changePassword,
                    title: const Text('Izmijeni lozinku'),
                    subtitle: const Text(
                      'Kao administrator ne trebate unositi staru lozinku',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onChanged: (v) => setState(() {
                      _changePassword = v ?? false;
                      if (!_changePassword) {
                        _newPwController.clear();
                        _confirmPwController.clear();
                      }
                    }),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_changePassword) ...[
                    const SizedBox(height: 12),
                    Form(
                      key: _pwFormKey,
                      child: Column(
                        children: [
                          _pwField(
                            label: 'Nova lozinka',
                            controller: _newPwController,
                            obscure: _obscureNew,
                            onToggle: () =>
                                setState(() => _obscureNew = !_obscureNew),
                            validator: AppValidators.password,
                          ),
                          const SizedBox(height: 12),
                          _pwField(
                            label: 'Potvrdi novu lozinku',
                            controller: _confirmPwController,
                            obscure: _obscureConfirm,
                            onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            validator: AppValidators.confirmPassword(
                                () => _newPwController.text),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _updateEmployee,
                icon: const Icon(Icons.save),
                label: const Text('Sačuvaj izmjene'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _field(String label, TextEditingController ctrl,
      {bool required = true, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label je obavezno' : null
              : null),
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
    );
  }

  Widget _pwField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        helperText: label == 'Nova lozinka'
            ? 'Min. 6 znakova, veliko/malo slovo, cifra'
            : null,
        helperMaxLines: 2,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
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
