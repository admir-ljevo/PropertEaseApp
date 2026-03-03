import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:propertease_client/screens/conversations/conversations_list_screen.dart';
import 'package:propertease_client/screens/reservations/reservation_list_screen.dart';
import 'package:propertease_client/screens/users/client_edit_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/application_user.dart';
import '../providers/application_user_provider.dart';
import '../screens/notifications/notification_list.dart';
import '../screens/property/property_list.dart';

class MasterScreenWidget extends StatefulWidget {
  Widget? child;
  String? title;
  Widget? title_widget;

  MasterScreenWidget({this.child, this.title, this.title_widget, super.key});

  @override
  State<StatefulWidget> createState() => MasterScreenWidgetState();
}

class MasterScreenWidgetState extends State<MasterScreenWidget> {
  late UserProvider _userProvider;
  late ApplicationUser user;

  String? firstName;
  String? lastName;
  String? photoUrl;
  int? roleId;
  int? userId;
  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = int.tryParse(prefs.getString('userId')!)!;
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');

      photoUrl = prefs.getString('profilePhoto');
      roleId = prefs.getInt('roleId');
      getUserById(userId!);
    });
  }

  Future<void> getUserById(int id) async {
    try {
      var fetchedUser = await _userProvider.getClientById(id);
      setState(() {
        user = fetchedUser;
      });
    } catch (e) {
      throw (e.toString());
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
    getUserIdFromSharedPreferences();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _userProvider = context.read<UserProvider>();
    getUserIdFromSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: widget.title_widget ?? Text(widget.title ?? ""),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            SizedBox(
              height: 80,
              child: PopupMenuButton<String>(
                onSelected: (String choice) async {
                  if (choice == 'Profile') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserEditScreen(
                          user: user,
                        ),
                      ),
                    );
                  } else if (choice == 'Logout') {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('authToken');
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => LoginWidget()));
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Profile',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Profile'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Logout',
                    child: ListTile(
                      leading: Icon(Icons.exit_to_app),
                      title: Text('Logout'),
                    ),
                  ),
                ],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Container(
                        height: 60,
                        width: 50,
                        child: ClipOval(
                          child: (photoUrl!.isNotEmpty)
                              ? Image.memory(
                                  base64Decode(photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  "assets/images/user_placeholder.jpg",
                                  fit: BoxFit.cover),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Profile",
                              style: TextStyle(
                                  color: Colors
                                      .blue)), // Label above the user's name
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("$firstName $lastName"),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ), // Indicator icon
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              title: Text("Properties"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const PropertyListWidget()));
              },
            ),
            ListTile(
              title: const Text("News"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const NewsListWidget()));
              },
            ),
            ListTile(
              title: const Text("Reservations"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ReservationListScreen()));
              },
            ),
            ListTile(
              title: const Text("Conversations"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ConversationListScreen(
                          clientId: userId,
                        )));
              },
            ),
          ],
        ),
      ),
      body: widget.child!,
    );
  }
}
