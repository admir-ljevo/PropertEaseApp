import 'package:json_annotation/json_annotation.dart';

import 'application_role.dart';
import 'application_user.dart';

part 'application_user_role.g.dart';

@JsonSerializable()
class ApplicationUserRole {
  int? id;
  ApplicationUser? user; // Use the ApplicationUser class
  ApplicationRole? role; // Use the ApplicationRole class
  DateTime? createdAt;
  DateTime? modifiedAt;
  bool? isDeleted;

  ApplicationUserRole({
    this.id,
    this.user,
    this.role,
    this.createdAt,
    this.modifiedAt,
    this.isDeleted,
  });

  factory ApplicationUserRole.fromJson(Map<String, dynamic> json) =>
      _$ApplicationUserRoleFromJson(json);

  Map<String, dynamic> toJson() => _$ApplicationUserRoleToJson(this);
}
