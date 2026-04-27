import 'package:flutter/material.dart';

class ReservationStatus {
  static const int pending   = 0;
  static const int confirmed = 1;
  static const int completed = 2;
  static const int cancelled = 3;

  static String label(int? status) {
    if (status == pending)   return 'Na čekanju';
    if (status == confirmed) return 'Potvrđena';
    if (status == completed) return 'Završena';
    if (status == cancelled) return 'Otkazana';
    return '/';
  }

  static Color backgroundColor(int? status) {
    if (status == pending)   return Colors.orange.shade100;
    if (status == confirmed) return Colors.green.shade100;
    if (status == completed) return Colors.blue.shade100;
    if (status == cancelled) return Colors.red.shade100;
    return Colors.grey.shade100;
  }

  static Color textColor(int? status) {
    if (status == pending)   return Colors.orange.shade800;
    if (status == confirmed) return Colors.green.shade800;
    if (status == completed) return Colors.blue.shade800;
    if (status == cancelled) return Colors.red.shade800;
    return Colors.grey.shade600;
  }

  static Widget chip(int? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label(status),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor(status),
        ),
      ),
    );
  }
}
