// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_user_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationUserRole _$ApplicationUserRoleFromJson(Map<String, dynamic> json) =>
    ApplicationUserRole(
      id: json['id'] as int?,
      user: json['user'] == null
          ? null
          : ApplicationUser.fromJson(json['user'] as Map<String, dynamic>),
      role: json['role'] == null
          ? null
          : ApplicationRole.fromJson(json['role'] as Map<String, dynamic>),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      isDeleted: json['isDeleted'] as bool?,
    );

Map<String, dynamic> _$ApplicationUserRoleToJson(
        ApplicationUserRole instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'role': instance.role,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'isDeleted': instance.isDeleted,
    };
