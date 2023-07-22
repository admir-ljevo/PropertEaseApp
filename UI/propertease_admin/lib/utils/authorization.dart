import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Authorization {
  static String? username;
  static String? password;
}

// Image createImageUrl(int? propertyId, {int imageId = 1}) {
//   var photo = Image.network(
//       "https://localhost:44340/api/Photo/propertyId/$propertyId/imageId/$imageId");

// }
String formatNumber(dynamic) {
  var f = NumberFormat('###,00');
  if (dynamic == null) return "";

  return f.format(dynamic);
}
