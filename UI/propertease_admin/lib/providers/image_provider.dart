import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:propertease_admin/models/photo.dart';

class PhotoProvider with ChangeNotifier {
  static String? _baseUrl;
  String _endpoint = "Photo";

  PhotoProvider() {
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://localhost:44340/api/");
  }

  Future<Image> getFirstImageByPropertyId(int? propertyId) async {
    var url = "$_baseUrl$_endpoint/GetFirstImage/propertyId/$propertyId";

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      Photo data = Photo.fromJson(jsonDecode(response.body));
      String? imgUrl = data.url;
      return Image.network("https://localhost:44340/$imgUrl");
    } else {
      return Image.asset("assets/images/house_placeholder.jpg");
    }
  }

  Map<String, String> createHeaders() {
    var headers = {
      "Content-Type": "application/json",
      // "Authorization": basicAuth,
    };
    return headers;
  }
}
