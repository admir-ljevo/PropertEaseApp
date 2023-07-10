import 'package:flutter/material.dart';
import 'package:propertease_admin/providers/property_provider.dart';
import 'package:propertease_admin/screens/property_list_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => PropertyProvider())],
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

class LoginWidget extends StatelessWidget {
  LoginWidget({super.key});

  TextEditingController _usernameController = new TextEditingController();
  TextEditingController _passwordController = new TextEditingController();

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
                    "assets/images/OIP.jpg",
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(
                    height: 10,
                    width: 10,
                  ),
                  TextField(
                    decoration: InputDecoration(
                        labelText: 'Username', prefixIcon: Icon(Icons.mail)),
                    controller: _usernameController,
                  ),
                  const SizedBox(
                    height: 10,
                    width: 10,
                  ),
                  TextField(
                    decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.password)),
                    controller: _passwordController,
                  ),
                  const SizedBox(
                    height: 10,
                    width: 10,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        var password = _passwordController.text;
                        var username = _usernameController.text;
                        Authorization.username = username;
                        Authorization.password = password;
                        print(username + "  " + password);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PropertyListWidget(),
                          ),
                        );
                      },
                      child: const Text("Login"))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
