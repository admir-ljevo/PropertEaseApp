import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatNumber(dynamic input) {
  if (input == null) return ""; // Handle null input

  if (input is! num) {
    input = double.tryParse(input.toString());
    if (input == null) return "";
  }

  return input.toStringAsFixed(2);
}
