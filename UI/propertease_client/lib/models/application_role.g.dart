// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationRole _$ApplicationRoleFromJson(Map<String, dynamic> json) =>
    ApplicationRole(
      id: json['id'] as int?,
      roleLevel: json['roleLevel'] as int?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      isDeleted: json['isDeleted'] as bool?,
      roles: (json['roles'] as List<dynamic>?)
          ?.map((e) => ApplicationUserRole.fromJson(e as Map<String, dynamic>))
          .toList(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$ApplicationRoleToJson(ApplicationRole instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roleLevel': instance.roleLevel,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'name': instance.name,
      'roles': instance.roles,
    };
