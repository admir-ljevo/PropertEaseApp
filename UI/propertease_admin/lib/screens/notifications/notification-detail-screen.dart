import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/new.dart';
import 'package:propertease_admin/screens/notifications/notification_edit_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';

const _kPrimary = Color(0xFF115892);

class NotificationDetailScreen extends StatefulWidget {
  final New? notification;
  const NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late New? _news;

  @override
  void initState() {
    super.initState();
    _news = widget.notification;
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push<New>(
      context,
      MaterialPageRoute(
          builder: (_) => NotificationEditScreen(notification: _news)),
    );
    if (updated != null && mounted) {
      setState(() => _news = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _news;
    if (n == null) {
      return const Scaffold(body: Center(child: Text('Vijest nije pronađena')));
    }

    final date = n.createdAt != null
        ? DateFormat('dd.MM.yyyy – HH:mm').format(n.createdAt!)
        : '—';
    final author =
        '${n.user?.person?.firstName ?? ''} ${n.user?.person?.lastName ?? ''}'
            .trim();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Detalji vijesti'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (Authorization.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Uredi',
              onPressed: _openEdit,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroImage(n),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.name ?? '',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _MetaChip(
                            icon: Icons.person_outline,
                            label: author.isNotEmpty ? author : '—',
                          ),
                          const SizedBox(width: 12),
                          _MetaChip(
                            icon: Icons.calendar_today_outlined,
                            label: date,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),

                      Text(
                        n.text ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(New n) {
    if (n.image != null && n.image!.isNotEmpty) {
      return Image.network(
        '${AppConfig.serverBase}/${n.image}',
        height: 320,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() => Container(
        height: 200,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.newspaper, size: 72, color: Colors.grey),
        ),
      );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kPrimary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: _kPrimary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
