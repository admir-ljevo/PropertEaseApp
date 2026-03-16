import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = Authorization.userId;
    if (userId == null) return;
    try {
      final provider = context.read<ReservationNotificationProvider>();
      final items = await provider.getByUser(userId);
      await provider.markAllSeen(userId);
      if (mounted) setState(() => _notifications = items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onTap(ReservationNotification n) async {
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
      appBar: AppBar(title: const Text('Obavijesti')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Nema obavijesti',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    final photoUrl = n.propertyPhotoUrl != null &&
                            n.propertyPhotoUrl!.isNotEmpty
                        ? '${AppConfig.serverBase}${n.propertyPhotoUrl}'
                        : null;
                    final isSeen = n.isSeen ?? true;

                    return InkWell(
                      onTap: () => _onTap(n),
                      child: Container(
                        color: isSeen ? null : const Color(0xFFE8F0FE),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: photoUrl != null
                                    ? Image.network(photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _placeholder())
                                    : _placeholder(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (n.propertyName != null)
                                    Text(
                                      n.propertyName!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (n.reservationNumber != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Rezervacija: ${n.reservationNumber}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54),
                                      ),
                                    ),
                                  if (n.message != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(n.message!,
                                          style:
                                              const TextStyle(fontSize: 13)),
                                    ),
                                  if (n.createdAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _formatDate(n.createdAt!),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!isSeen)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: CircleAvatar(
                                    radius: 5,
                                    backgroundColor: Color(0xFF115892)),
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

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Prije ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Prije ${diff.inHours} h';
    return 'Prije ${diff.inDays} dana';
  }
}
