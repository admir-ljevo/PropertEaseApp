import 'package:flutter/material.dart';
import 'package:propertease_admin/providers/auth_provider.dart';
import 'package:propertease_admin/utils/app_navigator.dart';
import 'package:propertease_admin/providers/city_provider.dart';
import 'package:propertease_admin/providers/image_provider.dart';
import 'package:propertease_admin/providers/notification_provider.dart';
import 'package:propertease_admin/providers/property_provider.dart';
import 'package:propertease_admin/providers/property_reservation_provider.dart';
import 'package:propertease_admin/providers/property_type_provider.dart';
import 'package:propertease_admin/screens/property/property_list_screen.dart';
import 'package:provider/provider.dart';
import 'providers/application_role_provider.dart';
import 'providers/application_user_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/country_provider.dart';
import 'providers/message_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/property_rating_provider.dart';
import 'providers/reservation_notification_provider.dart';
import 'providers/user_rating_provider.dart';

void main() {
  onUnauthorized = () {
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginWidget()),
      (_) => false,
    );
  };
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ChangeNotifierProvider(create: (_) => PhotoProvider()),
      ChangeNotifierProvider(create: (_) => PropertyTypeProvider()),
      ChangeNotifierProvider(create: (_) => CityProvider()),
      ChangeNotifierProvider(create: (_) => PropertyReservationProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => RoleProvider()),
      ChangeNotifierProvider(create: (_) => CountryProvider()),
      ChangeNotifierProvider(create: (_) => ConversationProvider()),
      ChangeNotifierProvider(create: (_) => MessageProvider()),
      ChangeNotifierProvider(create: (_) => ReservationNotificationProvider()),
      ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ChangeNotifierProvider(create: (_) => PropertyRatingProvider()),
      ChangeNotifierProvider(create: (_) => UserRatingProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1565C0);
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'PropertEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 1,
          centerTitle: false,
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
      ),
      home: const LoginWidget(),
    );
  }
}

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PropertyListWidget()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('PropertEase – Prijava')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/OIP.jpg', height: 80, width: 80),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Korisničko ime',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Unesite korisničko ime.'
                          : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Lozinka',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Unesite lozinku.' : null,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 8),

                    if (auth.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(
                          auth.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Prijava'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
