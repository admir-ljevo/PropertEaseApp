import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import 'application_user.dart';
part 'new.g.dart';

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
class New {
  int? id;
  String? name;
  int? userId;
  ApplicationUser? user;
  String? image;
  String? imageBytes;
  String? text;
  DateTime? createdAt;
  DateTime? modifiedAt;
  int? totalRecordsCount;
  bool? isDeleted;

  New({
    this.id = 0,
    this.name,
    this.userId = 1,
    this.image,
    this.imageBytes,
    this.text,
    this.createdAt,
    this.modifiedAt,
    this.totalRecordsCount = 0,
    this.isDeleted = false,
  });

  @FileConverter()
  File? file;

  factory New.fromJson(Map<String, dynamic> json) => _$NewFromJson(json);

  Map<String, dynamic> toJson() => _$NewToJson(this);
}
