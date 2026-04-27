import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signalr_core/signalr_core.dart';

import 'package:propertease_admin/config/app_config.dart';
import '../../models/reservation_notification.dart';
import '../../providers/property_reservation_provider.dart';
import '../../providers/reservation_notification_provider.dart';
import '../../utils/authorization.dart';
import '../reservation/reservation_detail_screen.dart';

class ReservationNotificationListScreen extends StatefulWidget {
  const ReservationNotificationListScreen({super.key});

  @override
  State<ReservationNotificationListScreen> createState() =>
      _ReservationNotificationListScreenState();
}

class _ReservationNotificationListScreenState
    extends State<ReservationNotificationListScreen> {
  List<ReservationNotification> _notifications = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 10;

  HubConnection? _hub;

  @override
  void initState() {
    super.initState();
    _load();
    _connectSignalR();
  }

  @override
  void dispose() {
    _hub?.stop();
    super.dispose();
  }

  Future<void> _connectSignalR() async {
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

      _hub!.on('NewNotification', (_) => _load());
      await _hub!.start();
    } catch (_) {
      // polling continues as fallback
    }
  }

  Future<void> _load() async {
    final userId = Authorization.userId;
    if (userId == null) return;
    try {
      final items = await context
          .read<ReservationNotificationProvider>()
          .getByUser(userId, page: 1, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _notifications = items;
          _loading = false;
          _page = 1;
          _hasMore = items.length >= _pageSize;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final userId = Authorization.userId;
    if (userId == null) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final items = await context
          .read<ReservationNotificationProvider>()
          .getByUser(userId, page: nextPage, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _notifications = [..._notifications, ...items];
          _page = nextPage;
          _hasMore = items.length >= _pageSize;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _markSeen(ReservationNotification n) {
    if (n.id == null) return;
    context.read<ReservationNotificationProvider>().markSeen(n.id!).ignore();
    final idx = _notifications.indexOf(n);
    if (idx >= 0 && mounted) {
      setState(() {
        _notifications[idx] = ReservationNotification(
          id: n.id, userId: n.userId, reservationId: n.reservationId,
          title: n.title, message: n.message, isSeen: true,
          reservationNumber: n.reservationNumber, propertyName: n.propertyName,
          propertyPhotoUrl: n.propertyPhotoUrl, createdAt: n.createdAt,
        );
      });
    }
  }

  Future<void> _markAllSeen() async {
    final userId = Authorization.userId;
    if (userId == null) return;
    context.read<ReservationNotificationProvider>().markAllSeen(userId).ignore();
    setState(() {
      _notifications = _notifications.map((n) => ReservationNotification(
        id: n.id, userId: n.userId, reservationId: n.reservationId,
        title: n.title, message: n.message, isSeen: true,
        reservationNumber: n.reservationNumber, propertyName: n.propertyName,
        propertyPhotoUrl: n.propertyPhotoUrl, createdAt: n.createdAt,
      )).toList();
    });
  }

  Future<void> _onTap(ReservationNotification n) async {
    if (n.id != null && n.isSeen == false) {
      context.read<ReservationNotificationProvider>().markSeen(n.id!).ignore();
      final idx = _notifications.indexOf(n);
      if (idx >= 0 && mounted) {
        setState(() {
          _notifications[idx] = ReservationNotification(
            id: n.id, userId: n.userId, reservationId: n.reservationId,
            title: n.title, message: n.message, isSeen: true,
            reservationNumber: n.reservationNumber, propertyName: n.propertyName,
            propertyPhotoUrl: n.propertyPhotoUrl, createdAt: n.createdAt,
          );
        });
      }
    }

    if (n.reservationId == null) return;
    try {
      final reservation = await context
          .read<PropertyReservationProvider>()
          .getById(n.reservationId!);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReservationDetailsScreen(reservation: reservation),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rezervacija nije pronađena')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obavijesti'),
        actions: [
          if (_notifications.any((n) => n.isSeen == false))
            IconButton(
              tooltip: 'Označi sve kao pročitano',
              icon: const Icon(Icons.done_all),
              onPressed: _markAllSeen,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Nema obavijesti', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _notifications.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, i) =>
                      i < _notifications.length - 1 ? const Divider(height: 1) : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    if (index == _notifications.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: _loadingMore
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : TextButton.icon(
                                  onPressed: _loadMore,
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('Učitaj više'),
                                ),
                        ),
                      );
                    }
                    final n = _notifications[index];
                    final photoUrl = (n.propertyPhotoUrl?.isNotEmpty == true)
                        ? '${AppConfig.serverBase}${n.propertyPhotoUrl}'
                        : null;
                    final isSeen = n.isSeen ?? true;

                    return InkWell(
                      onTap: () => _onTap(n),
                      child: Container(
                        color: isSeen ? null : const Color(0xFFE8F0FE),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 56, height: 56,
                                child: photoUrl != null
                                    ? Image.network(photoUrl, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _placeholder())
                                    : _placeholder(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (n.title != null)
                                    Text(
                                      n.title!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (n.message != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(n.message!,
                                          style: const TextStyle(fontSize: 13)),
                                    ),
                                  if (n.reservationNumber != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text('Rez: ${n.reservationNumber}',
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.black54)),
                                    ),
                                  if (n.createdAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        DateFormat('dd.MM.yyyy HH:mm')
                                            .format(n.createdAt!.toLocal()),
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!isSeen)
                              IconButton(
                                tooltip: 'Označi kao pročitano',
                                icon: const Icon(Icons.check_circle_outline,
                                    color: Color(0xFF115892), size: 22),
                                onPressed: () => _markSeen(n),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.home, color: Colors.grey),
      );
}
