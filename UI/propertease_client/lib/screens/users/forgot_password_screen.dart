import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:propertease_client/providers/application_user_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  final _resetFormKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _step2 = false;
  bool _loading = false;

  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final error = await _userProvider.forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      if (error != null) {
        _showError(error);
        return;
      }
      setState(() => _step2 = true);
      _showSnack('Kod je poslan na email ako je registrovan.', Colors.green);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final error = await _userProvider.resetPassword(
        _emailController.text.trim(),
        _otpController.text.trim(),
        _newPassController.text,
      );
      if (!mounted) return;
      if (error != null) {
        _showError(error);
        return;
      }
      _showSnack('Lozinka je uspješno promijenjena.', Colors.green);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _showError(String msg) => _showSnack(msg, Colors.red);

  static String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Unesite email adresu';
    final re = RegExp(r'^[\w\-.+]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Unesite ispravnu email adresu';
    return null;
  }

  static String? _validateOtp(String? v) {
    if (v == null || v.trim().isEmpty) return 'Unesite kod';
    if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) return 'Kod mora biti 6 cifara';
    return null;
  }

  String? _validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'Unesite novu lozinku';
    if (v.length < 8) return 'Lozinka mora imati najmanje 8 znakova';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Lozinka mora sadržavati veliko slovo';
    if (!RegExp(r'\d').hasMatch(v)) return 'Lozinka mora sadržavati broj';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Potvrdite novu lozinku';
    if (v != _newPassController.text) return 'Lozinke se ne podudaraju';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF115892)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF115892),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF115892).withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 16),
                Text(
                  _step2 ? 'Unesite kod' : 'Zaboravljena lozinka',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF115892),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _step2
                      ? 'Provjerite email i unesite primljeni kod\nte novu lozinku.'
                      : 'Unesite email vezan za vaš nalog.\nPoslaćemo vam kod za resetovanje.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 28),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _step2 ? _buildStep2() : _buildStep1(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _requestOtp(),
            decoration: const InputDecoration(
              labelText: 'Email adresa',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _requestOtp,
                    child: const Text('Pošalji kod'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined,
                    size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _emailController.text,
                    style: TextStyle(
                        fontSize: 13, color: Colors.blue.shade800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _step2 = false),
                  child: const Text(
                    'Promijeni',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF115892),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Kod (6 cifara)',
              prefixIcon: Icon(Icons.pin_outlined),
              counterText: '',
            ),
            validator: _validateOtp,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _newPassController,
            obscureText: _obscureNew,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nova lozinka',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: _validateNewPassword,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPassController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
            decoration: InputDecoration(
              labelText: 'Potvrda lozinke',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: _validateConfirm,
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text('Resetuj lozinku'),
                  ),
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: _loading ? null : _requestOtp,
              child: const Text(
                'Nisam primio kod — pošalji ponovo',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF115892)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
