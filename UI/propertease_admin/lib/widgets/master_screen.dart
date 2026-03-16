import 'package:flutter/material.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/main.dart';
import 'package:propertease_admin/providers/conversation_provider.dart';
import 'package:propertease_admin/providers/reservation_notification_provider.dart';
import 'package:propertease_admin/screens/notifications/notification-list-screen.dart';
import 'package:propertease_admin/screens/notifications/reservation_notification_list_screen.dart';
import 'package:propertease_admin/screens/profile/profile_edit_screen.dart';
import 'package:propertease_admin/screens/reports/renter_reservation_report_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';

import 'package:propertease_admin/screens/reservation/reservation_list_screen.dart';
import 'package:propertease_admin/screens/users/user_list_screen.dart';

import '../screens/admin/city_list_screen.dart';
import '../screens/admin/country_list_screen.dart';
import '../screens/admin/property_type_list_screen.dart';
import '../screens/admin/role_list_screen.dart';
import '../screens/messaging/conversation_list_screen.dart';
import '../screens/property/property_list_screen.dart';

class MasterScreenWidget extends StatefulWidget {
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
  State<MasterScreenWidget> createState() => _MasterScreenWidgetState();
}

class _MasterScreenWidgetState extends State<MasterScreenWidget> {
  int _unreadCount = 0;
  int _unseenNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _fetchUnseenNotifCount();
  }

  Future<void> _fetchUnreadCount() async {
    final userId = Authorization.userId;
    if (userId == null) return;
    try {
      final provider = context.read<ConversationProvider>();
      final count = await provider.getUnreadCount(userId);
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _fetchUnseenNotifCount() async {
    final userId = Authorization.userId;
    if (userId == null) return;
    try {
      final provider = context.read<ReservationNotificationProvider>();
      final count = await provider.getUnseenCount(userId);
      if (mounted) setState(() => _unseenNotifCount = count);
    } catch (_) {}
  }

  void _openProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileEditScreen()))
        .then((changed) {
      if (changed == true && mounted) {
        setState(() {}); // refresh sidebar display name / photo
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = Authorization.profilePhoto;
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: widget.titleWidget ?? Text(widget.title ?? ''),
      ),
      drawer: Drawer(
        child: ListView(children: [
          // ── User profile header ───────────────────────────────────────────
          InkWell(
            onTap: _openProfile,
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFF115892)),
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    backgroundImage: hasPhoto
                        ? NetworkImage('${AppConfig.serverBase}$photoPath')
                        : null,
                    child: !hasPhoto
                        ? const Icon(Icons.person,
                            size: 32, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Authorization.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Authorization.role ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, color: Colors.white54, size: 18),
                ],
              ),
            ),
          ),
          // ── Nav items ─────────────────────────────────────────────────────
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
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const RenterReservationReportScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.newspaper_outlined),
            title: const Text('Vijesti'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const NewsListWidget()));
            },
          ),
          ListTile(
            leading: Badge(
              isLabelVisible: _unseenNotifCount > 0,
              label: Text('$_unseenNotifCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            title: const Text('Obavijesti'),
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) =>
                          const ReservationNotificationListScreen()))
                  .then((_) => _fetchUnseenNotifCount());
            },
          ),
          if (Authorization.isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Users'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const UserListWidget()));
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text('Reference data',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Countries'),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CountryListScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: const Text('Cities'),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CityListScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Property Types'),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PropertyTypeListScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Roles'),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RoleListScreen())),
            ),
          ],
          ListTile(
            leading: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.inbox),
            ),
            title: const Text('Inbox'),
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => const ConversationListScreen()))
                  .then((_) => _fetchUnreadCount());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Moj profil'),
            onTap: _openProfile,
          ),
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
      body: widget.child ?? const SizedBox.shrink(),
    );
  }
}
