import 'package:flutter/material.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:propertease_admin/main.dart';
import 'package:propertease_admin/providers/conversation_provider.dart';
import 'package:propertease_admin/providers/reservation_notification_provider.dart';
import 'package:propertease_admin/screens/notifications/notification-list-screen.dart';
import 'package:propertease_admin/screens/notifications/reservation_notification_list_screen.dart';
import 'package:propertease_admin/screens/profile/profile_edit_screen.dart';
import 'package:propertease_admin/screens/reports/renter_reservation_report_screen.dart';
import 'package:propertease_admin/providers/auth_provider.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';

import 'package:propertease_admin/screens/reservation/reservation_list_screen.dart';
import 'package:propertease_admin/screens/users/user_list_screen.dart';

import '../screens/admin/city_list_screen.dart';
import '../screens/admin/country_list_screen.dart';
import '../screens/admin/payment_list_screen.dart';
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
  HubConnection? _hub;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _fetchUnseenNotifCount();
    _connectSignalR();
  }

  @override
  void dispose() {
    _hub?.stop();
    super.dispose();
  }

  void _connectSignalR() async {
    final token = Authorization.token;
    if (token == null) return;
    try {
      _hub = HubConnectionBuilder()
          .withUrl(
            '${AppConfig.serverBase}/hubs/messageHub',
            HttpConnectionOptions(
              accessTokenFactory: () async => token,
              logging: (level, message) {},
            ),
          )
          .withAutomaticReconnect()
          .build();
      _hub!.on('newMessage', (_) => _fetchUnreadCount());
      _hub!.on('NewNotification', (_) => _fetchUnseenNotifCount());
      await _hub!.start();
    } catch (_) {}
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

  Widget _navLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 2),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1.0,
          ),
        ),
      );

  Widget _navTile(IconData icon, String title, VoidCallback onTap,
      {int badge = 0, Color? color}) {
    return ListTile(
      dense: true,
      leading: badge > 0
          ? Badge(
              label: Text('$badge'),
              child: Icon(icon, color: color, size: 22),
            )
          : Icon(icon, color: color, size: 22),
      title: Text(title,
          style: TextStyle(
              fontSize: 14, color: color, fontWeight: FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }

  void _openProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileEditScreen()))
        .then((changed) {
      if (changed == true && mounted) {
        setState(() {});
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
        child: Column(children: [
          InkWell(
            onTap: _openProfile,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    backgroundImage: hasPhoto
                        ? NetworkImage('${AppConfig.serverBase}$photoPath')
                        : null,
                    child: !hasPhoto
                        ? const Icon(Icons.person, size: 30, color: Colors.white)
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            Authorization.role ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
              _navLabel('Glavno'),
              _navTile(Icons.home_outlined, 'Nekretnine', () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const PropertyListWidget()));
              }),
              _navTile(Icons.calendar_month_outlined, 'Rezervacije', () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const ReservationListWidget()));
              }),
              _navTile(Icons.inbox_outlined, 'Inbox', () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => const ConversationListScreen()))
                    .then((_) => _fetchUnreadCount());
              }, badge: _unreadCount),
              _navTile(Icons.notifications_outlined, 'Obavijesti', () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (_) => const ReservationNotificationListScreen()))
                    .then((_) => _fetchUnseenNotifCount());
              }, badge: _unseenNotifCount),
              const Divider(height: 16),
              _navLabel('Analitika'),
              _navTile(Icons.bar_chart_outlined, 'Izvještaji', () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const RenterReservationReportScreen()));
              }),
              _navTile(Icons.newspaper_outlined, 'Vijesti', () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const NewsListWidget()));
              }),
              if (Authorization.isAdmin) ...[
                const Divider(height: 16),
                _navLabel('Administracija'),
                _navTile(Icons.people_outline, 'Korisnici', () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const UserListWidget()));
                }),
                _navTile(Icons.flag_outlined, 'Države', () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CountryListScreen()))),
                _navTile(Icons.location_city_outlined, 'Gradovi', () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CityListScreen()))),
                _navTile(Icons.category_outlined, 'Tipovi nekretnina', () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PropertyTypeListScreen()))),
                _navTile(Icons.admin_panel_settings_outlined, 'Uloge', () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RoleListScreen()))),
                _navTile(Icons.payment_outlined, 'Plaćanja', () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaymentListScreen()))),
              ],
              const Divider(height: 16),
              _navTile(Icons.manage_accounts_outlined, 'Moj profil', _openProfile),
              _navTile(Icons.logout, 'Odjava', () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginWidget()),
                    (_) => false,
                  );
                }
              }, color: Colors.red.shade700),
            ]),
          ),
        ]),
      ),
      body: widget.child ?? const SizedBox.shrink(),
    );
  }
}
