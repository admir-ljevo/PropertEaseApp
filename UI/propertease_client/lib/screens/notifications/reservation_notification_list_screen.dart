import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../models/reservation_notification.dart';
import '../../providers/reservation_notification_provider.dart';
import '../../utils/authorization.dart';
import '../reservations/reservation_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obavijesti'),
        backgroundColor: const Color(0xFF115892),
        foregroundColor: Colors.white,
      ),
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
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return _NotificationTile(
                      notification: n,
                      onTap: () {
                        if (n.reservationId != null) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ReservationDetailsScreen(
                                reservationId: n.reservationId!),
                          ));
                        }
                      },
                    );
                  },
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final ReservationNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = notification.propertyPhotoUrl != null &&
            notification.propertyPhotoUrl!.isNotEmpty
        ? '${AppConfig.serverBase}${notification.propertyPhotoUrl}'
        : null;
    final isSeen = notification.isSeen ?? true;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSeen ? null : const Color(0xFFE8F0FE),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notification.propertyName != null)
                    Text(
                      notification.propertyName!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (notification.reservationNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Rezervacija: ${notification.reservationNumber}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  if (notification.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        notification.message!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  if (notification.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDate(notification.createdAt!),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
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
                  backgroundColor: Color(0xFF115892),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.home, color: Colors.grey),
      );

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Prije ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Prije ${diff.inHours} h';
    return 'Prije ${diff.inDays} dana';
  }
}
