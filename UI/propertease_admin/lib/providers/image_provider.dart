import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/photo.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

class PhotoProvider with ChangeNotifier {
  static String get _baseUrl => AppConfig.apiBase;
  String _endpoint = "Photo";
  Future<List<Photo>> getImagesByProperty(int? propertyId) async {
    var url = "$_baseUrl$_endpoint/propertyId/$propertyId";

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((item) => Photo.fromJson(item))
          .toList();
    } else {
      return [];
    }
  }

  Future<void> addPhoto(Photo photoDto) async {
    try {
      final url = Uri.parse('$_baseUrl$_endpoint/Add');
      final request = http.MultipartRequest('POST', url);

      final token = Authorization.token;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['Id'] = photoDto.id.toString();
      request.fields['CreatedAt'] = photoDto.createdAt!.toIso8601String();
      request.fields['Url'] = photoDto.url ?? '';
      request.fields['PropertyId'] = photoDto.propertyId.toString();
      request.fields['IsDeleted'] = photoDto.isDeleted.toString();
      request.fields['TotalRecordsCount'] =
          photoDto.totalRecordsCount.toString();

      request.files.add(
        await http.MultipartFile.fromPath('file', photoDto.file!.path,
            contentType: http_parser.MediaType('image', 'jpeg')),
      );

      final response = await request.send();
      if (response.statusCode != 200) {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> deletePhoto(int id) async {
    final url = Uri.parse('$_baseUrl${_endpoint}/$id');
    final response = await http.delete(url, headers: createHeaders());
    if (response.statusCode >= 300) {
      throw Exception('Failed to delete photo. Status: ${response.statusCode}');
    }
  }

  Future<Image> getFirstImageByPropertyId(int? propertyId) async {
    var url = "$_baseUrl$_endpoint/GetFirstImage/propertyId/$propertyId";

    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      Photo data = Photo.fromJson(jsonDecode(response.body));
      String? imgUrl = data.url;
      return Image.network('${AppConfig.serverBase}$imgUrl');
    } else {
      return Image.asset("assets/images/house_placeholder.jpg");
    }
  }

  Map<String, String> createHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = Authorization.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, String> createHeadersForUpload() {
    return {
      'Content-Type': 'multipart/form-data',
    };
  }
}
