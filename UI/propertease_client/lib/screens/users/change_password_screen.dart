import 'package:flutter/material.dart';
import 'package:propertease_client/providers/application_user_provider.dart';
import 'package:provider/provider.dart';

import '../../models/application_user.dart';

class ChangePasswordScreen extends StatefulWidget {
  ApplicationUser? user;
  ChangePasswordScreen({super.key, this.user});

  @override
  State<StatefulWidget> createState() => ChangePasswordScreenState();
}

class ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late UserProvider _userProvider;
  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String newPasswordError = ''; // Define an error message variable

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _userProvider = context.read<UserProvider>();
    _scaffoldKey.currentState;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16.0),
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Old Password",
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
              ),
              onChanged: (password) {
                // Validate the password
                if (!RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(password)) {
                  setState(() {
                    newPasswordError =
                        'Password must be at least 8 characters, with at least one uppercase letter and one digit.';
                  });
                } else {
                  // Password is valid
                  setState(() {
                    newPasswordError = '';
                  });
                }
              },
            ),
            Text(
              newPasswordError,
              style: const TextStyle(
                color: Colors.red, // Customize the error text color
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm New Password",
              ),
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () async {
                // Check if the newPassword and confirmPassword match
                if (_newPasswordController.text !=
                    _confirmPasswordController.text) {
                  // Display a SnackBar for the password mismatch
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "New Password and Confirm Password do not match."),
                      backgroundColor:
                          Colors.red, // Customize the SnackBar appearance
                    ),
                  );
                } else if (newPasswordError.isEmpty) {
                  try {
                    if (_newPasswordController.text ==
                        _oldPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Old password cannot be the same as new password"),
                        backgroundColor: Colors.red,
                      ));
                      return;
                    }
                    String? result = await _userProvider.changePassword(
                      _oldPasswordController.text,
                      _newPasswordController.text,
                      widget.user!.id!.toString(),
                    );

                    if (result == "Password changed successfully") {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Password changed successfully"),
                        backgroundColor: Colors.green,
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Old password doesn't match"),
                        backgroundColor:
                            Colors.red, // Customize the SnackBar appearance
                      ));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("An error occurred."),
                      backgroundColor:
                          Colors.red, // Customize the SnackBar appearance
                    ));
                  }
                }
              },
              child: const Text("Change Password"),
            )
          ],
        ),
      ),
    );
  }
}
