import 'dart:io';
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

@JsonSerializable()
class Photo {
  int? id;
  String? url;
  int? propertyId;
  bool? isDeleted = false;
  int? totalRecordsCount = 0;
  DateTime? createdAt = DateTime.now();

  @FileConverter()
  File? file;

  Photo(this.id, this.url, this.propertyId, this.file);

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoToJson(this);
}
