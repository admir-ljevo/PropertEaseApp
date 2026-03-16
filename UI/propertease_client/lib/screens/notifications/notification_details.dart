import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/new.dart';

const _kPrimary = Color(0xFF115892);

class NotificationDetailScreen extends StatelessWidget {
  final New? notification;
  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    if (n == null) {
      return const Scaffold(
          body: Center(child: Text('Vijest nije pronađena')));
    }

    final date = n.createdAt != null
        ? DateFormat('dd.MM.yyyy – HH:mm').format(n.createdAt!)
        : '—';
    final author =
        '${n.user?.person?.firstName ?? ''} ${n.user?.person?.lastName ?? ''}'
            .trim();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // Collapsible app bar with hero image
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroImage(n),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    n.name ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Meta chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                          icon: Icons.person_outline,
                          label: author.isNotEmpty ? author : '—'),
                      _MetaChip(
                          icon: Icons.calendar_today_outlined,
                          label: date),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Body text
                  Text(
                    n.text ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.75,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(New n) {
    if (n.imageBytes != null && n.imageBytes!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(n.imageBytes!),
          fit: BoxFit.cover,
          width: double.infinity,
        );
      } catch (_) {}
    }
    return Container(
      color: _kPrimary.withOpacity(0.15),
      child: const Center(
        child: Icon(Icons.newspaper, size: 72, color: Colors.white54),
      ),
    );
  }
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
        color: _kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: _kPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
