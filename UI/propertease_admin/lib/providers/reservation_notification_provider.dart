import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/io_client.dart';

import '../config/app_config.dart';
import '../models/reservation_notification.dart';
import '../utils/authorization.dart';

class ReservationNotificationProvider with ChangeNotifier {
  static String get _baseUrl => AppConfig.apiBase;

  late IOClient _http;

  ReservationNotificationProvider() {
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    _http = IOClient(client);
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (Authorization.token != null)
          'Authorization': 'Bearer ${Authorization.token}',
      };

  Future<List<ReservationNotification>> getForMe(
      {int page = 1, int pageSize = 20}) async {
    final url =
        '${_baseUrl}ReservationNotification/me?page=$page&pageSize=$pageSize';
    final response = await _http.get(Uri.parse(url), headers: _headers());
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data
          .map((e) =>
              ReservationNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<int> getUnseenCount() async {
    final url = '${_baseUrl}ReservationNotification/me/unseen-count';
    final response = await _http.get(Uri.parse(url), headers: _headers());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as int?) ?? 0;
    }
    return 0;
  }

  Future<void> markAllSeen() async {
    final url = '${_baseUrl}ReservationNotification/me/mark-seen';
    await _http.put(Uri.parse(url), headers: _headers());
  }

  Future<void> markSeen(int notificationId) async {
    final url =
        '${_baseUrl}ReservationNotification/mark-seen-single/$notificationId';
    await _http.put(Uri.parse(url), headers: _headers());
  }
}
