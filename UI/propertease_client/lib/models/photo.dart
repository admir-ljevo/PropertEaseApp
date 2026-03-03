import 'dart:io';
import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

part 'photo.g.dart';

class FileConverter implements JsonConverter<File?, String?> {
  const FileConverter();

  @override
  File? fromJson(String? json) {
    return json != null ? File(json) : null;
  }

  @override
  String? toJson(File? file) {
    return file?.path;
  }
}

class Uint8ListConverter implements JsonConverter<Uint8List?, List<int>?> {
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(List<int>? json) {
    if (json == null) return null;
    return Uint8List.fromList(json);
  }

  @override
  List<int>? toJson(Uint8List? object) {
    if (object == null) return null;
    return object.toList();
  }
}

@JsonSerializable()
class Photo {
  int? id;
  String? url;
  int? propertyId;
  bool? isDeleted = false;
  int? totalRecordsCount = 0;
  DateTime? createdAt = DateTime.now();

  String? imageBytes;
  @FileConverter()
  File? file;

  Photo(this.id, this.url, this.propertyId, this.file, this.imageBytes);

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoToJson(this);
}
