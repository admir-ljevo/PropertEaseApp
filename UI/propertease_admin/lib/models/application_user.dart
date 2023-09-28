import 'package:json_annotation/json_annotation.dart';
import 'package:propertease_admin/models/person.dart';

part 'application_user.g.dart';

@JsonSerializable()
class ApplicationUser {
  int? id;
  bool? isDeleted;
  Person? person;

  ApplicationUser({this.id = 0, this.isDeleted = false, this.person});

  factory ApplicationUser.fromJson(Map<String, dynamic> json) =>
      _$ApplicationUserFromJson(json);

  Map<String, dynamic> toJson() => _$ApplicationUserToJson(this);
}
