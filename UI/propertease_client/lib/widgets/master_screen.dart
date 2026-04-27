import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:propertease_client/screens/conversations/conversations_list_screen.dart';
import 'package:propertease_client/screens/notifications/notification_list.dart';
import 'package:propertease_client/screens/notifications/reservation_notification_list_screen.dart';
import 'package:propertease_client/screens/property/property_list.dart';
import 'package:propertease_client/screens/reservations/reservation_list_screen.dart';
import 'package:propertease_client/screens/users/client_edit_screen.dart';
import 'package:propertease_client/utils/authorization.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/application_user.dart';
import '../providers/application_user_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/reservation_notification_provider.dart';

class MasterScreenWidget extends StatefulWidget {
  final Widget? child;
  final String? title;
  final Widget? titleWidget;
  final int currentIndex;
  final int? inboxUnreadCount;

  const MasterScreenWidget({
    this.child,
    this.title,
    this.titleWidget,
    this.currentIndex = 0,
    this.inboxUnreadCount,
    super.key,
  });

  @override
  State<MasterScreenWidget> createState() => _MasterScreenWidgetState();
}

class _MasterScreenWidgetState extends State<MasterScreenWidget> {
  ApplicationUser? _user;
  int _unreadCount = 0;
  int _unseenNotifCount = 0;
  HubConnection? _hub;

  static const _kPrimary = Color(0xFF115892);

  @override
  void initState() {
    super.initState();
    _loadUser();
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

  Future<void> _loadUser() async {
    if (Authorization.userId == null) return;
    try {
      final provider = context.read<UserProvider>();
      final u = await provider.getClientById(Authorization.userId!);
      if (mounted) setState(() => _user = u);
    } catch (_) {}
  }

  void _openProfile() {
    if (_user == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => UserEditScreen(user: _user!)))
        .then((_) => _loadUser());
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Da li ste sigurni da se želite odjaviti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () {
              Authorization.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginWidget()),
                (_) => false,
              );
            },
            child: const Text('Odjavi se', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index == widget.currentIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PropertyListWidget()),
          (_) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ReservationListScreen()),
          (_) => false,
        );
        break;
      case 2:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NewsListWidget()),
          (_) => false,
        );
        break;
      case 3:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ConversationListScreen(
              clientId: Authorization.userId,
            ),
          ),
          (_) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoBytes = Authorization.profilePhotoBytes;
    final hasPhoto = photoBytes != null && photoBytes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: widget.titleWidget ?? Text(widget.title ?? ''),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Notification bell
          IconButton(
            tooltip: 'Obavijesti',
            icon: Badge(
              isLabelVisible: _unseenNotifCount > 0,
              label: Text('$_unseenNotifCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) =>
                          const ReservationNotificationListScreen()))
                  .then((_) => _fetchUnseenNotifCount());
            },
          ),
          // Profile avatar button
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: _openProfile,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      hasPhoto ? MemoryImage(base64Decode(photoBytes)) : null,
                  child: !hasPhoto
                      ? const Icon(Icons.person, size: 18, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odjava',
            onPressed: _logout,
          ),
        ],
      ),
      body: widget.child ?? const SizedBox.shrink(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.currentIndex,
        onDestinationSelected: _onTabTapped,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Nekretnine',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Rezervacije',
          ),
          const NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'Vijesti',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: (widget.inboxUnreadCount ?? _unreadCount) > 0,
              label: Text('${widget.inboxUnreadCount ?? _unreadCount}'),
              child: const Icon(Icons.inbox_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: (widget.inboxUnreadCount ?? _unreadCount) > 0,
              label: Text('${widget.inboxUnreadCount ?? _unreadCount}'),
              child: const Icon(Icons.inbox),
            ),
            label: 'Inbox',
          ),
        ],
      ),
    );
  }
}
