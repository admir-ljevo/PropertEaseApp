import 'package:flutter/material.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/models/property_type.dart';
import 'package:propertease_admin/providers/application_role_provider.dart';
import 'package:propertease_admin/providers/city_provider.dart';
import 'package:propertease_admin/providers/image_provider.dart';
import 'package:propertease_admin/providers/notification_provider.dart';
import 'package:propertease_admin/providers/property_provider.dart';
import 'package:propertease_admin/providers/property_reservation_provider.dart';
import 'package:propertease_admin/providers/property_type_provider.dart';
import 'package:propertease_admin/screens/property/property_list_screen.dart';
import 'package:propertease_admin/screens/users/renter_add_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/application_user_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/message_provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ChangeNotifierProvider(create: (_) => PhotoProvider()),
      ChangeNotifierProvider(create: (_) => PropertyTypeProvider()),
      ChangeNotifierProvider(create: (_) => CityProvider()),
      ChangeNotifierProvider(create: (_) => PropertyReservationProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => RoleProvider()),
      ChangeNotifierProvider(create: (_) => ConversationProvider()),
      ChangeNotifierProvider(create: (_) => MessageProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: LoginWidget(),
    );
  }
}

// class MyBarWidget extends StatelessWidget {
//   String title;

//   MyBarWidget({super.key, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Text(title);
//   }
// }

class LoginWidget extends StatefulWidget {
  LoginWidget({super.key});

  @override
  State<StatefulWidget> createState() => LoginWidgetState();
}

class LoginWidgetState extends State<LoginWidget> {
  TextEditingController _usernameController = new TextEditingController();
  TextEditingController _passwordController = new TextEditingController();
  late UserProvider _userProvider;
  bool isObscure = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _userProvider = context.read<UserProvider>();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
  }

  void showUnsucessfullLoginMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wrong username and/or password '),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showSucessfullLoginMessage(String username) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text('Welcome, $username',
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        duration: const Duration(seconds: 10), // Show for 3 seconds
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            // Handle the action if needed
          },
        ),
        behavior: SnackBarBehavior.floating, // Adds a floating animation
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
          width: 400,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(10.10),
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/user_placeholder.jpg",
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(
                    height: 10,
                    width: 10,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        labelText: 'Username', prefixIcon: Icon(Icons.mail)),
                    controller: _usernameController,
                  ),
                  const SizedBox(
                    height: 10,
                    width: 10,
                  ),
                  Stack(
                    alignment:
                        Alignment.centerRight, // Align the icon to the right
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.password),
                        ),
                        controller: _passwordController,
                        obscureText:
                            isObscure, // Set obscureText based on the isObscure variable
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isObscure =
                                !isObscure; // Toggle the obscureText property
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 12.0), // Adjust the padding as needed
                          child: Icon(
                            isObscure
                                ? Icons.visibility_off
                                : Icons
                                    .visibility, // Toggle between showing/hiding the password
                            color: Colors.grey, // Customize the icon's color
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      var password = _passwordController.text;
                      var username = _usernameController.text;

                      // Call the signIn function to authenticate
                      final Map<String, dynamic>? loginResult =
                          await _userProvider.signIn(
                        _usernameController.text,
                        _passwordController.text,
                      );

                      if (loginResult != null) {
                        final String authToken = loginResult['accessToken'];
                        final String userId = loginResult['userId'];
                        final String firstName = loginResult['firstName'];
                        final String lastName = loginResult['lastName'];
                        final String profilePhoto = loginResult['profilePhoto'];
                        final int roleId = loginResult['roleId'];
                        final SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setString('authToken', authToken);
                        prefs.setString('userId', userId); // Store the userId
                        prefs.setString('firstName', firstName);
                        prefs.setString('lastName', lastName);
                        prefs.setString('profilePhoto', profilePhoto);
                        prefs.setInt('roleId', roleId);
                        showSucessfullLoginMessage(username);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PropertyListWidget(),
                          ),
                        );
                      } else {
                        showUnsucessfullLoginMessage();
                      }
                    },
                    child: const Text("Login"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RenterAddScreen(),
                        ),
                      );
                    },
                    child: const Text("Create an account"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
