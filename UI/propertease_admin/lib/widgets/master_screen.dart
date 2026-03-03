import 'package:flutter/material.dart';
import 'package:propertease_admin/main.dart';
import 'package:propertease_admin/screens/notifications/notification-list-screen.dart';
import 'package:propertease_admin/screens/reports/renter_reservation_report_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';

import 'package:propertease_admin/screens/reservation/reservation_list_screen.dart';
import 'package:propertease_admin/screens/users/user_list_screen.dart';

import '../screens/messaging/conversation_list_screen.dart';
import '../screens/property/property_list_screen.dart';

class MasterScreenWidget extends StatelessWidget {
  final Widget? child;
  final String? title;
  final Widget? titleWidget;

  const MasterScreenWidget({
    this.child,
    this.title,
    this.titleWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: titleWidget ?? Text(title ?? ''),
      ),
      drawer: Drawer(
        child: ListView(children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF115892)),
            child: Text('PropertEase',
                style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Nekretnine'),
            onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => const PropertyListWidget()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Rezervacije'),
            onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => const ReservationListWidget()));
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Reports"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const RenterReservationReportScreen()));
            },
          ),
          ListTile(
            title: const Text("Notifications"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const NewsListWidget()));
            },
          ),
          if (Authorization.role == 'Administrator')
            ListTile(
              title: const Text("Users"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const UserListWidget()));
              },
            ),
          ListTile(
            title: const Text("Conversations"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ConversationListScreen(
                        renterId: Authorization.userId,
                      )));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Odjava'),
            onTap: () {
              Authorization.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginWidget()),
                (_) => false,
              );
            },
          ),
        ]),
      ),
      body: child ?? const SizedBox.shrink(),
    );
  }
}
