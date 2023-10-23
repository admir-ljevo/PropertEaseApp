// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationUser _$ApplicationUserFromJson(Map<String, dynamic> json) =>
    ApplicationUser(
      id: json['id'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      active: json['active'] as bool? ?? true,
      personId: json['personId'] as int? ?? 0,
      isAdministrator: json['isAdministrator'] as bool? ?? false,
      isEmployee: json['isEmployee'] as bool? ?? false,
      isClient: json['isClient'] as bool? ?? false,
      userName: json['userName'] as String? ?? "",
      email: json['email'] as String? ?? "",
      phoneNumber: json['phoneNumber'] as String? ?? "",
    )
      ..person = json['person'] == null
          ? null
          : Person.fromJson(json['person'] as Map<String, dynamic>)
      ..userRoles = (json['userRoles'] as List<dynamic>?)
          ?.map((e) => ApplicationUserRole.fromJson(e as Map<String, dynamic>))
          .toList()
      ..file = const FileConverter().fromJson(json['file'] as String?);

Map<String, dynamic> _$ApplicationUserToJson(ApplicationUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'isDeleted': instance.isDeleted,
      'createdAt': instance.createdAt?.toIso8601String(),
      'active': instance.active,
      'personId': instance.personId,
      'person': instance.person,
      'isAdministrator': instance.isAdministrator,
      'isEmployee': instance.isEmployee,
      'isClient': instance.isClient,
      'userName': instance.userName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'userRoles': instance.userRoles,
      'file': const FileConverter().toJson(instance.file),
    };
