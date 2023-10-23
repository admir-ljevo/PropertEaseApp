import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:propertease_admin/main.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:propertease_admin/screens/notifications/notification-list-screen.dart';
import 'package:propertease_admin/screens/reports/renter_reservation_report_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:propertease_admin/screens/reservation/reservation_list_screen.dart';
import 'package:propertease_admin/screens/users/user_list_screen.dart';

import '../screens/property/property_list_screen.dart';
import '../screens/users/user_detail_screen.dart';

class MasterScreenWidget extends StatefulWidget {
  Widget? child;
  String? title;
  Widget? title_widget;
  MasterScreenWidget({this.child, this.title, this.title_widget, super.key});
  @override
  State<MasterScreenWidget> createState() => _MasterScreenWidgetState();
}

class _MasterScreenWidgetState extends State<MasterScreenWidget> {
  late ApplicationUser user;
  late UserProvider _userProvider;
  String? firstName;
  String? lastName;
  String photoUrl = 'https://localhost:44340';
  int? roleId;
  int? userId;
  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = int.tryParse(prefs.getString('userId')!)!;
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');
      photoUrl = 'https://localhost:44340${prefs.getString('profilePhoto')}';
      roleId = prefs.getInt('roleId')!;
      getUserById(userId!);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _userProvider = context.read<UserProvider>();
    getUserIdFromSharedPreferences();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
    getUserIdFromSharedPreferences();
  }

  Future<void> getUserById(int id) async {
    try {
      var fetchedUser = await _userProvider.GetEmployeeById(id);
      setState(() {
        user = fetchedUser;
      });
    } catch (e) {
      throw (e.toString());
    }
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserDetailScreen(
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
            title: const Text("Reports"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const RenterReservationReportScreen()));
            },
          ),
          ListTile(
            title: const Text("News"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const NewsListWidget()));
            },
          ),
          if (roleId == 1)
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
