import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:http/io_client.dart';

import '../models/photo.dart';

class PhotoProvider with ChangeNotifier {
  static String? _baseUrl;
  String _endpoint = "Photo";
  HttpClient client = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Allow connections to any https server, regardless of the certificate
      return true;
    };
  IOClient? http;

  PhotoProvider() {
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://10.0.2.2:7137/api/");

    client.badCertificateCallback = (cert, host, port) => true;
    http = IOClient(client);
  }
  Future<List<Photo>> getImagesByProperty(int? propertyId) async {
    var url = "$_baseUrl$_endpoint/propertyId/$propertyId";

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http!.get(uri, headers: headers);

    List<Image> images = [];

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((item) => Photo.fromJson(item))
          .toList();
    } else {
      // Handle the case when the API request fails or returns a non-200 status code.
      // You might want to return an empty list or handle the error as needed.
      return [];
    }
  }

  Future<Image> getFirstImageByPropertyId(int? propertyId) async {
    var url = "$_baseUrl$_endpoint/GetFirstImage/propertyId/$propertyId";

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http!.get(uri, headers: headers);

    if (response.statusCode == 200) {
      Photo data = Photo.fromJson(jsonDecode(response.body));
      String? imgUrl = data.url;

      // Check if imageBytes is available and not empty
      if (data.imageBytes != null) {
        return Image.memory(base64Decode(data.imageBytes!));
      } else {
        // Fallback to network image or placeholder image
        return Image.network("https://10.0.2.2:7137$imgUrl");
        // Or return a placeholder image if you have one
        // return Image.asset("assets/images/placeholder.jpg");
      }
    } else {
      // Handle server error, e.g., return a placeholder image
      return Image.asset("assets/images/house_placeholder.jpg");
    }
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
