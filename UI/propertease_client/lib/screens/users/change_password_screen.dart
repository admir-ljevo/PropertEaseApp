import 'package:flutter/material.dart';
import 'package:propertease_client/providers/application_user_provider.dart';
import 'package:provider/provider.dart';

import 'package:propertease_client/models/application_user.dart';

class ChangePasswordScreen extends StatefulWidget {
  final ApplicationUser? user;
  const ChangePasswordScreen({super.key, this.user});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late UserProvider _userProvider;
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final error = await _userProvider.changePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      if (!mounted) return;
      if (error == null) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lozinka uspješno promijenjena'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Greška: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promjena lozinke')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _pwField(
                controller: _oldPasswordController,
                label: 'Trenutna lozinka',
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
                validator: (v) => (v == null || v.isEmpty) ? 'Unesite trenutnu lozinku' : null,
              ),
              const SizedBox(height: 16),
              _pwField(
                controller: _newPasswordController,
                label: 'Nova lozinka',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Unesite novu lozinku';
                  if (v.length < 8) return 'Lozinka mora imati najmanje 8 znakova';
                  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Lozinka mora sadržavati veliko slovo';
                  if (!RegExp(r'\d').hasMatch(v)) return 'Lozinka mora sadržavati broj';
                  if (v == _oldPasswordController.text) return 'Nova lozinka mora biti različita od trenutne';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _pwField(
                controller: _confirmPasswordController,
                label: 'Potvrdi novu lozinku',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Unesite potvrdu lozinke';
                  if (v != _newPasswordController.text) return 'Lozinke se ne podudaraju';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Promijeni lozinku'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pwField({
    required TextEditingController controller,
    required String label,
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
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
