import 'package:flutter/material.dart';
import 'package:propertease_client/providers/property_provider.dart';
import 'package:propertease_client/providers/rating_provider.dart';
import 'package:propertease_client/screens/users/client_add_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/application_user_provider.dart';
import 'providers/city_provider.dart';
import 'providers/image_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/property_type_provider.dart';
import 'screens/property/property_list.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ChangeNotifierProvider(create: (_) => PropertyTypeProvider()),
      ChangeNotifierProvider(create: (_) => CityProvider()),
      ChangeNotifierProvider(create: (_) => PhotoProvider()),
      ChangeNotifierProvider(create: (_) => RatingProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginWidget(),
    );
  }
}

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<StatefulWidget> createState() => LoginWidgetState();
}

class LoginWidgetState extends State<LoginWidget> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late UserProvider _userProvider;

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
        title: const Text(
          'Login',
          style: TextStyle(color: Colors.blue),
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
          width: 400,
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                // Wrap the Column with a SingleChildScrollView
                child: Column(
                  children: [
                    Image.asset(
                      "assets/images/user_placeholder.jpg",
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,

                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(
                          Icons.mail,
                          color: Colors.blue,
                        ),
                      ),
                      // Replace this with your controller
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextField(
                          controller: _passwordController,

                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(
                              Icons.password,
                              color: Colors.blue,
                            ),
                          ),
                          obscureText: true,
                          // Replace this with your controller
                        ),
                        GestureDetector(
                          onTap: () {
                            // Toggle password visibility
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: Icon(
                              Icons.visibility_off,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                          final String profilePhoto =
                              loginResult['profilePhoto'];
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
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ClientAddScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Create an account",
                        style: TextStyle(color: Colors.blue),
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
