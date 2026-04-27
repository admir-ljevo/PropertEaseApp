import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Called by BaseProvider whenever the API returns 401.
/// Wired up in main() before runApp so it has access to LoginWidget.
VoidCallback? onUnauthorized;
