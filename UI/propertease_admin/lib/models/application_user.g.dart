// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationUser _$ApplicationUserFromJson(Map<String, dynamic> json) =>
    ApplicationUser(
      id: json['id'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      person: json['person'] == null
          ? null
          : Person.fromJson(json['person'] as Map<String, dynamic>),
    )
      ..createdAt = json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String)
      ..active = json['active'] as bool?
      ..personId = json['personId'] as int?
      ..isAdministrator = json['isAdministrator'] as bool?
      ..isEmployee = json['isEmployee'] as bool?
      ..isClient = json['isClient'] as bool?
      ..userName = json['userName'] as String?
      ..email = json['email'] as String?
      ..phoneNumber = json['phoneNumber'] as String?
      ..userRoles = (json['userRoles'] as List<dynamic>?)
          ?.map((e) => ApplicationUserRole.fromJson(e as Map<String, dynamic>))
          .toList();

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
    };
