import 'dart:io';
import 'package:json_annotation/json_annotation.dart';
import 'application_user_role.dart';
import 'person.dart';

part 'application_user.g.dart';

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
class ApplicationUser {
  int? id;
  bool? isDeleted;
  DateTime? createdAt;
  bool? active;
  int? personId;
  Person? person;
  bool? isAdministrator;
  bool? isEmployee;
  bool? isClient;
  String? userName;
  String? email;
  String? phoneNumber;
  List<ApplicationUserRole>? userRoles;

  @FileConverter() // Add the FileConverter annotation to the userFile property
  File? file;

  ApplicationUser({
    this.id = 0,
    this.isDeleted = false,
    this.createdAt,
    this.active = true,
    this.personId = 0,
    this.isAdministrator = false,
    this.isEmployee = false,
    this.isClient = false,
    this.userName = "",
    this.email = "",
    this.phoneNumber = "",
  });

  factory ApplicationUser.fromJson(Map<String, dynamic> json) =>
      _$ApplicationUserFromJson(json);

  Map<String, dynamic> toJson() => _$ApplicationUserToJson(this);
}
