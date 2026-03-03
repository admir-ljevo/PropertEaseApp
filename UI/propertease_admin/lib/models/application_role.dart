import 'package:json_annotation/json_annotation.dart';

import 'application_user_role.dart';

part 'application_role.g.dart';

@JsonSerializable()
class ApplicationRole {
  int? id;
  int? roleLevel;
  DateTime? createdAt;
  DateTime? modifiedAt;
  bool? isDeleted;
  String? name;
  List<ApplicationUserRole>? roles; // Add the Roles property

  ApplicationRole({
    this.id,
    this.roleLevel,
    this.createdAt,
    this.modifiedAt,
    this.isDeleted,
    this.roles,
    this.name, // Initialize the Roles property
  });

  factory ApplicationRole.fromJson(Map<String, dynamic> json) =>
      _$ApplicationRoleFromJson(json);

  Map<String, dynamic> toJson() => _$ApplicationRoleToJson(this);
}
