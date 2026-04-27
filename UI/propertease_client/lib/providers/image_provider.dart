import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:http/io_client.dart';

import '../config/app_config.dart';
import '../models/photo.dart';

class PhotoProvider with ChangeNotifier {
  final String _endpoint = "Photo";
  HttpClient client = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      return true;
    };
  IOClient? http;

  PhotoProvider() {
    client.badCertificateCallback = (cert, host, port) => true;
    http = IOClient(client);
  }
  Future<List<Photo>> getImagesByProperty(int? propertyId) async {
    var url = "${AppConfig.apiBase}$_endpoint/propertyId/$propertyId";

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http!.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((item) => Photo.fromJson(item))
          .toList();
    } else {
      return [];
    }
  }

  Future<Image> getFirstImageByPropertyId(int? propertyId) async {
    var url = "${AppConfig.apiBase}$_endpoint/GetFirstImage/propertyId/$propertyId";

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http!.get(uri, headers: headers);

    if (response.statusCode == 200) {
      Photo data = Photo.fromJson(jsonDecode(response.body));
      if (data.url != null && data.url!.isNotEmpty) {
        return Image.network('${AppConfig.serverBase}${data.url}');
      }
    }
    return Image.asset("assets/images/house_placeholder.jpg");
  }

  Map<String, String> createHeaders() {
    var headers = {
      'Content-Type': 'application/json; charset=utf-8',
      // "Authorization": basicAuth,
    };
    return headers;
  }

  Map<String, String> createHeadersForUpload() {
    var headers = {
      'Content-Type': 'multipart/form-data',
      // "Authorization": basicAuth,
    };
    return headers;
  }
}
