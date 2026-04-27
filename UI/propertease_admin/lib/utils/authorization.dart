import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Authorization {
  static String? token;
  static String? username;
  static int? userId;
  static String? role;
  static int? roleId;
  static bool isRenter = false;
  static String? firstName;
  static String? lastName;
  static String? profilePhoto;
  static String? profilePhotoBytes;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;
  static bool get isAdmin => role == 'Admin';

  static String get displayName {
    final parts = [firstName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : (username ?? '');
  }

  static void clear() {
    token = null;
    username = null;
    userId = null;
    role = null;
    roleId = null;
    isRenter = false;
    firstName = null;
    lastName = null;
    profilePhoto = null;
    profilePhotoBytes = null;
  }
}

String formatNumber(dynamic) {
  var f = NumberFormat('###,00');
  if (dynamic == null) return "";

  return f.format(dynamic);
}
