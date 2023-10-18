import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:propertease_admin/main.dart';
import 'package:propertease_admin/screens/notifications/notification-list-screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:propertease_admin/screens/reservation/reservation_list_screen.dart';
import 'package:propertease_admin/screens/users/user_list_screen.dart';

import '../screens/property/property_list_screen.dart';

class MasterScreenWidget extends StatefulWidget {
  Widget? child;
  String? title;
  Widget? title_widget;
  MasterScreenWidget({this.child, this.title, this.title_widget, super.key});
  @override
  State<MasterScreenWidget> createState() => _MasterScreenWidgetState();
}

class _MasterScreenWidgetState extends State<MasterScreenWidget> {
  String? firstName;
  String? lastName;
  String photoUrl = 'https://localhost:44340';
  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');
      photoUrl = 'https://localhost:44340${prefs.getString('profilePhoto')}';
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserIdFromSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.title_widget ?? Text(widget.title ?? ""),
      ),
      drawer: Drawer(
        child: ListView(children: [
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 80,
            child: PopupMenuButton<String>(
              onSelected: (String choice) async {
                if (choice == 'Profile') {
                  // Handle the profile option
                  // Add your navigation logic to the profile page here
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
                PopupMenuItem<String>(
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
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                        ),
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
                            Icon(Icons.arrow_drop_down),
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
            title: const Text("Properties"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const PropertyListWidget()));
            },
          ),
          ListTile(
            title: const Text("Reservations"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ReservationListWidget()));
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
            title: const Text("Users"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const UserListWidget()));
            },
          ),
        ]),
      ),
      body: widget.child!,
    );
  }
}
