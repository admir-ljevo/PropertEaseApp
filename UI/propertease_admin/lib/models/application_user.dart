import 'package:json_annotation/json_annotation.dart';
import 'package:propertease_admin/models/person.dart';

import 'application_user_role.dart';

part 'application_user.g.dart';

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
  ApplicationUser({
    this.id = 0,
    this.isDeleted = false,
    this.person,
    this.userRoles,
  });

  factory ApplicationUser.fromJson(Map<String, dynamic> json) =>
      _$ApplicationUserFromJson(json);

  Map<String, dynamic> toJson() => _$ApplicationUserToJson(this);
}
