import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Authorization {
  static String? token;
  static String? username;
  static int? userId;
  static String? role;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static void clear() {
    token = null;
    username = null;
    userId = null;
    role = null;
  }
}

String formatNumber(dynamic) {
  var f = NumberFormat('###,00');
  if (dynamic == null) return "";

  return f.format(dynamic);
}
